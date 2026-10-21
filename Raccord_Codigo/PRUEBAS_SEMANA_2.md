# Semana 2 — Pruebas unitarias con AAA y umbral en CI

Capa trabajada: **API** (reglas de negocio del backend FastAPI) + **Front** (lógica pura Dart) + **E2E/CI** (workflow y umbral).

## Cómo correr

```bash
# Backend
cd raccord_backend/api_usuarios
pip install -r requirements-dev.txt
python -m pytest                 # cobertura + umbral (fail_under en pyproject.toml)
python -m pytest -k login_guard --no-cov -v   # una sola parte

# Frontend
cd raccord_flutter
flutter test --coverage
```

No necesitan Docker, base de datos, MinIO ni red (FIRST): la BD se sustituye por SQLite en memoria o dobles, y el reloj se fija por parámetro o con `monkeypatch`.

## Qué se prueba (backend: 378 tests, cobertura real 32,1 %)

| Unidad | Regla de negocio | Valores límite |
|---|---|---|
| `utils/permissions.py` | Matriz de 5 roles × permisos; rol/permiso desconocido se deniega | ids 1000, 1006, `None` |
| `utils/login_guard.py` (RNF-004) | 5 fallos/15 min bloquean cuenta; 20/h bloquean IP; 10/24 h exigen administrador; éxito limpia fallos; mensaje genérico | 4 vs 5 fallos, 19 vs 20, ±1 s del vencimiento |
| `utils/rate_limit.py` | Máximo N llamadas por ventana, `Retry-After` | N vs N+1, 59 s vs 60 s |
| `utils/security.py`, `hash.py` | JWT (expirado, manipulado, otra clave, `jti` único); bcrypt 12 rondas, truncado a 72 | 71/72/73 caracteres |
| `utils/module_access.py` | La excepción por persona solo restringe, nunca amplía el rol | excepción = rol |
| `utils/project_scope.py` | Rol efectivo por proyecto (no por JWT), vínculo suspendido = no miembro, aislamiento por cliente | cadena de resolvers rota |
| `middleware/auth.py`, `token_revocation.py` | 401 por token inválido/vencido/revocado; 403 sin permiso | — |
| `utils/script_parser.py` | Detección de sluglines, momento del día, personajes con ≥2 intervenciones; PDF generado en memoria | lugar de 100+ caracteres, 3 vs 4 palabras |
| `schemas/*` | Contraseña 8–72, catálogos cerrados (estado de proyecto/escena/guion…), honeypot | 7/8 y 72/73 caracteres |
| `controllers` (puras) | Suspensión exige causal y solo ahí; escape de `%`/`_` en búsquedas | — |
| `utils/mail.py`, `watermark.py` | Escape HTML y saltos de línea; marca de agua con correo y fecha fija | — |
| `models/*` | Relaciones y FKs se resuelven (detecta errores sin BD) | — |

Frontend (Dart): `permissions.dart` (espejo de la matriz), `json_utils.dart`, `date_utils.dart`.

## Mutación manual (8 mutantes, todos detectados)

| # | Mutante | Test que lo detecta |
|---|---|---|
| 1 | `login_guard`: `>= MAX_FALLOS_CUENTA` → `>` | `test_quinto_fallo_bloquea_la_cuenta` |
| 2 | `login_guard`: `fallos_ip >= MAX_FALLOS_IP` → `>` | `test_veinte_fallos_de_una_ip_..._bloquean_la_ip` |
| 3 | `module_access`: `<` → `>` (permitiría ampliar acceso) | `test_excepcion_mas_restrictiva_se_aplica` |
| 4 | `rate_limit`: `now - t < window` → `<=` | `test_tras_expirar_la_ventana_se_vuelve_a_permitir` |
| 5 | `rate_limit`: `>= max_attempts` → `>` | `test_permite_hasta_el_maximo_y_rechaza_el_siguiente` |
| 6 | `project_controller`: `== "suspendido"` → `!=` | `test_suspendido_con_causal_es_valido` |
| 7 | `permissions`: `get(permission, False)` → `True` | `test_has_permission_permiso_inexistente_se_niega` |
| 8 | `script_parser`: `len(palabras) > 3` → `> 4` | `test_clean_character_name[A B C D-None]` |

Para el PR, copiar 1–2 de estos (el que cada integrante haya probado) en la descripción.

## Cobertura y exclusiones

- Medida sobre **todo `app/`** (4 074 sentencias; los paquetes tienen `__init__.py` para que los archivos sin tests cuenten como 0 %).
- Única exclusión: `app/utils/encrypt_existing_objects.py`, script de operación manual de una sola vez (sin lógica de negocio).
- Controllers/routes que necesitan PostgreSQL siguen en 0 %: se cubren con pruebas de integración (semanas siguientes).
- Umbral actual: **30** (`pyproject.toml`). Cierre de semana: PR que solo cambie `fail_under` a `max(30, floor(cobertura real))`.
- Frontend: `coverage_threshold.txt` = 30. `flutter test --coverage` solo cuenta archivos que algún test importa; al sumar tests de más archivos hay que revisar el valor.

## CI

`github-workflows/tests.yml` → copiar a `.github/workflows/tests.yml` en la **raíz del repositorio git** (la carpeta `PROYECTO`). Jobs: `backend-fastapi`, `frontend-flutter`, `evidencia-individual`.

Comprobar el rojo: subir `fail_under` a 99, push, confirmar ❌, devolver a 30 y confirmar ✅.

Regla de rama: Settings → Rules → Rulesets → *Require status checks* con `backend-fastapi` y `frontend-flutter`. Si el repo es privado y la cuenta es gratuita no se aplica: registrar en la matriz la regla manual «nadie fusiona un PR en rojo».
