# Pruebas — Semana 8 (CI completo y calidad de la suite)

Rama: `test/semana-08` · [PR #14](https://github.com/Cayayago/raccord_pruebas/pull/14). Capa de Javier: **E2E** (workflow, jobs `integration` y `e2e`, rojo provocado) + backend al 80 %. Capa de Deiver: **Front** (≥ 80 %, artefacto de cobertura, rojo provocado) — ver sección 7.

## 1. Estado inicial del CI (antes de la S8)

| Job | Qué hacía | Tests omitidos | Duración aprox. |
|---|---|---|---|
| `backend-fastapi` | pytest con cobertura | 8 (los de `tests/integracion`, que piden BD) | ~40 s |
| `frontend-flutter` | `flutter test --coverage` | 0 | ~1 min |
| `integration` | no existía | — | — |
| `e2e` | no existía | — | — |

Checks obligatorios en `main`: solo `backend-fastapi` y `frontend-flutter`.

## 2. Workflow (`.github/workflows/tests.yml`)

| Job | Qué hace | Detalle de calidad |
|---|---|---|
| `backend-fastapi` | unitarias con cobertura, `fail_under = 80` | artefacto `coverage-backend` (HTML) |
| `integration` | PostgreSQL 18 como *service*, migraciones con `psql`, `pytest tests/integracion` | falla si hay 0 tests o **algún omitido** (se lee el JUnit); artefacto `integracion-junit` |
| `e2e` | PostgreSQL como *service*, backend con `webServer`, Flutter Web compilado **desde el commit**, Playwright (api + ui) | `E2E_FRONT_CORREGIDO=true` (los tests de doble clic corren normales); reporte `playwright-report` si falla |
| `frontend-flutter` | sin cambios (lo extiende Deiver) | — |

Cachés: pip (backend e integración), Flutter y pnpm (`e2e/pnpm-lock.yaml`).

**Cero omitidos.** El primer run del e2e en CI salió con 51 tests y **24 omitidos**: los tests de API pedían `PROJECT_ID`, `ADMIN_*` y un usuario por rol que solo existían en el `.env` local. Se resolvió con `e2e/global-setup.ts`, que crea esos datos por API si faltan. Resultado: **52 pasan, 0 omitidos**.

## 3. Rojo provocado y corrección

| | Commit | Resultado |
|---|---|---|
| Rojo | `9f652e5e` — `ROJO PROVOCADO` (se rompió una aserción de `proyectos.spec.ts`) | `e2e` en rojo: 1 falló (con reintento #1) y 51 pasaron; `trace.zip` en el reporte |
| Corrección | `bbf8ad65` — revert | 5 checks en verde, 52 E2E pasan |

Links de los runs: **RELLENAR** (rojo: `https://github.com/Cayayago/raccord_pruebas/actions/runs/…` · verde: `…`).

## 4. Backend ≥ 80 %

| | Semana 7 | Semana 8 | Umbral |
|---|---|---|---|
| Backend | 75.14 % | **81.55 %** (698 tests) | `fail_under = 80` |

Tests nuevos (57), elegidos por lo que protegen:

- `tests/test_controladores_semana8.py` (35): clientes (correo único, una empresa solo ve la suya), roles (nombre único, PATCH solo toca lo enviado), Crew List (la persona no cambia de proyecto) y desgloses (uno con escenas asociadas no se puede borrar).
- `tests/test_login_controller_semana8.py` (22): correo inexistente y contraseña mala responden **igual** (sin enumeración de usuarios), cada fallo cuenta para el bloqueo, cuenta suspendida o suspendida en todos sus proyectos no entra, el 2FA exige la contraseña en cada paso y el código vence y no se reutiliza.

### Mutante de la capa

Se cambió `all(e == "suspendido" …)` por `any(…)` en `_validar_credenciales` (una persona suspendida en un solo proyecto quedaba fuera de todos).

| Mutante | Resultado |
|---|---|
| `all` → `any` en la suspensión por proyecto | **detectado**: falla `test_suspendido_solo_en_algunos_proyectos_si_entra` |

## 5. Ramas sin cubrir

Lo que queda (18.5 %) se agrupa así; no se cubrió a propósito:

| Zona | Por qué queda fuera |
|---|---|
| `app/utils/mail.py` (18 %) y `minio_client.py` (38 %) | Dependencias externas (SMTP, S3). El correo se prueba con dobles de `Notifier` (S5); un MinIO real no está disponible en CI (la imagen `minio/minio` no se puede bajar desde Docker Hub ni quay.io en el runner). |
| `script_controller`, `user_controller` | Candidatos de la S9: son los de más sentencias sin cubrir. |
| Líneas sueltas (`login_guard` 72, `notifier` 25, `project_scope` 100, `script_parser` 307) | Ramas defensivas de una línea cada una. |

## 6. Hallazgos

1. **Imagen de MinIO no disponible en CI.** `docker pull minio/minio` → *denied* y el espejo de quay.io → 401. Se quitó MinIO del job `e2e`; el backend arranca avisando que no hay buckets y los E2E no suben archivos. La subida real sigue cubierta en local (`docker-compose.test.yml`).
2. **24 tests omitidos en CI sin que nadie se enterara.** Un test omitido da verde. Ahora el job `integration` falla si omite alguno y el `e2e` se verifica con el conteo (52/0).
3. **`fill` no registra en Flutter** (login, registro, recuperar): el valor queda en el `<input>` pero el framework no lo toma. Todos los campos se escriben con `escribirEn` (teclado + comprobación del valor).
4. **Recuperar contraseña sin SMTP** responde `MAIL_ERROR` (correcto desde la S5). El E2E simula la respuesta con `page.route` y se añadió el caso en que el correo falla.
5. Observación (sin test): `update_client_full` (PUT) no valida correo duplicado y `create` sí.

## 7. Parte de Deiver (Front)

- Frontend 63.65 % → **≥ 80 %** y subir `coverage_threshold.txt`.
- Job `frontend-flutter`: subir la cobertura como artefacto.
- Rojo provocado propio + su corrección, con links en su PR.
- Su propio PR/commits; Javier lo revisa.
- Pendientes S6/S7: capa BD, E2E del flujo 1 (registro/login), doble clic en Registrar/Ingresar, mutante.
- Cambios que debe conocer: `campo()` y `escribirEn` (`e2e/tests/support/campos.ts`), `global-setup.ts`, y `registro.spec.ts` ahora usa `escribirEn`.

## 8. Pendiente antes del merge

- Ruleset de `main`: agregar `integration` y `e2e` como obligatorios y probarlo con un PR de test roto (cerrado sin merge).
- Rellenar los links de la sección 3.
- Revisión de Deiver (otra capa).
- Este PR trae también los commits de S6/S7 (sus PR siguen abiertos).

Comandos: desde `e2e/`, `pnpm test`. Backend: `python -m pytest` en `raccord_backend/api_usuarios`.
