# Pruebas — Semana 4 (API)

Tema: probar el API de FastAPI con `TestClient`, sin base de datos. Cada integrante lo mira desde el ángulo de su capa. Piso de cobertura al cerrar: **50 %** en frontend y backend.

## Preparación: probar el API sin infraestructura

Antes, `app/main.py` creaba las tablas y los buckets de MinIO **al importarse**, y `app/config/database.py` se conectaba a PostgreSQL al importarse. Así, `from app.main import app` exigía PostgreSQL y MinIO encendidos.

- Ahora eso pasa en el **arranque** del servidor (`lifespan` en `main.py`). Con `uvicorn` funciona igual que antes.
- `tests/conftest.py` tiene el fixture **`api`**:
  - Crea un `TestClient(app)` **sin** `with`, así que no corre el arranque.
  - Reemplaza `get_db` con `app.dependency_overrides` por un `FakeSession` (`tests/fakes.py`). Cada test decide qué "devuelve la BD" con `api.db.results[Modelo] = ...`.
  - Usa `raise_server_exceptions=False`, así que un error 500 se ve como lo vería el frontend.
- `requirements-dev.txt`: se agrega `httpx2`, que es lo que exige el `TestClient` de Starlette.

```python
def test_user_outside_project_gets_403(api):
    api.db.results[UserProject] = None          # Arrange: no pertenece al proyecto
    response = api.client.get(f"/characters/project/{PROYECTO}", headers=_auth())  # Act
    assert response.status_code == 403          # Assert
```

## Deiver — ángulo E2E: seguridad y contrato de errores

Archivo: `raccord_backend/api_usuarios/tests/test_api_seguridad.py` (16 tests).

| Escenario | Petición | Esperado |
|---|---|---|
| Sin token | `GET /projects` | `401` JSON `{"detail": "Not authenticated"}` (código + Content-Type + cuerpo) |
| Token firmado con otra clave | `GET /projects` | `401` "Token inválido o expirado" |
| Token vencido | `GET /projects` | `401` |
| Token cerrado con logout | `GET /projects` | `401` "Sesión cerrada. Vuelve a iniciar sesión." |
| Proyecto ajeno | `GET /characters/project/{id}` | `403` "No perteneces a este proyecto" |
| JWT de Administrador en proyecto ajeno | `GET /characters/project/{id}` | `403`: manda el rol del proyecto, no el del token |
| Suspendido en el proyecto | `GET /characters/project/{id}` | `403` |
| Rol Usuario sube una foto | `POST /scenes/{id}/fotos` | `403` |
| Administrador borra una foto | `DELETE /fotos/{id}` | `403` (el Admin ve fotos, no las borra) |
| Módulo bloqueado para la persona | `GET /scripts/project/{id}` | `403` "No tienes acceso a este módulo…" |
| Miembro autorizado | `GET /characters/project/{id}` | `200`, JSON, sobre `{success, message, data, error}` |
| JSON mal formado | `POST /register` | `400` JSON, `error: MALFORMED_JSON` |
| Tipos incorrectos | `POST /register` | `422` con `type/loc/msg`, **sin repetir lo enviado** |
| NIT duplicado | `POST /register` | mensaje genérico, `DUPLICATE_DATA`, **sin SQL** |
| Error inesperado | `GET /projects` (la BD falla) | `500` JSON genérico, sin detalles internos |
| Ruta inexistente | `GET /no-existe` | `404` JSON |

### Hallazgos (corregidos esta semana)

> 🔎 **Hallazgo:** `POST /register` con un NIT ya registrado devolvía en `error` el texto de la excepción de PostgreSQL: el nombre de la restricción (`users_id_identificacion_key`), el valor duplicado y la sentencia `INSERT INTO users (...)` completa, con todas las columnas de la tabla (incluida `contrasena`). Se comprobó contra PostgreSQL 16. **Corregido** en `register_controller.py`: ahora responde "Ya existe una cuenta con ese documento o correo." (`DUPLICATE_DATA`) y el detalle solo va al log. Lo mismo en las invitaciones masivas. Test: `test_register_duplicate_document_does_not_expose_sql`.

> 🔎 **Hallazgo:** un JSON mal formado respondía `422` con la lista cruda de errores de Pydantic. **Corregido** en `main.py`: ahora es `400` con un mensaje en JSON. Test: `test_malformed_json_responds_400_with_json_detail`.

> 🔎 **Hallazgo:** los errores `422` devolvían en `input` el valor enviado. Con un tipo incorrecto en `contrasena`, la respuesta repetía la contraseña. **Corregido** en `main.py`: solo se devuelve `type`, `loc` y `msg`, que es lo que usa el frontend. Test: `test_validation_error_does_not_echo_submitted_values`.

### Mutantes (todos detectados)

| Mutante | Test que lo detectó |
|---|---|
| `auth.py`: quitar `if is_token_revoked(...)` | `test_token_closed_with_logout_cannot_be_reused` |
| `project_scope.py`: ignorar `estado == "suspendido"` | `test_member_suspended_in_project_gets_403` |
| Volver al `error=str(e)` original del registro | `test_register_duplicate_document_does_not_expose_sql` |
| Quitar el manejador de `RequestValidationError` | `test_malformed_json…` y `test_validation_error_does_not_echo…` |

### Frontend al 50 % (parte de Deiver)

El frontend cerraba la S3 en 43,80 %. Para pasar el piso de 50 % se agregaron tests de lógica en Dart puro (sin pantallas), todos con `MockClient`, sin red:

| Archivo | Qué prueba |
|---|---|
| `test/core/api_client_test.dart` | Sobre `{success, data}`, cabecera Bearer, errores 401/422/502, descarga de bytes y subida multipart |
| `test/services/services_test.dart` | Qué pide cada servicio y cómo interpreta la respuesta (login, 2FA, proyectos, escenas, galería, accesos, roles) |
| `test/core/session_test.dart` | Rol por proyecto, sesión que sobrevive al reinicio, logout y `PlanChangeTracker` |
| `test/core/invite_helpers_test.dart`, `test/core/bulk_import_test.dart` | Carga masiva CSV/JSON fila por fila (`parseBulkJson`/`parseBulkCsv` con `@visibleForTesting`) |
| `test/models/models_test.dart` | JSON ↔ modelos; hallazgo "anochecer no existe en la BD" marcado con `skip` |

Resultado en el CI del PR #7: **118 tests, frontend 63,65 %**, backend 62,70 %. Umbrales: `coverage_threshold.txt` = 63, `fail_under` = 62.

## Javier — ángulo BD (propuesta)

Endpoints cuya respuesta depende de lo guardado, con el `FakeSession`:
- Duplicados: personaje con código repetido, correo de usuario repetido.
- Dependientes: no borrar un personaje con actores, ni un día de rodaje con escenas (por API).
- Búsquedas y filtros: escenas por guion o por día de rodaje, fotos por escena y papelera.

## Cómo correrlo

```bash
cd Raccord_Codigo/raccord_backend/api_usuarios
pip install -r requirements-dev.txt
python -m pytest tests/test_api_seguridad.py -v --no-cov   # solo esta semana
python -m pytest                                          # todo, con cobertura
```

Para enviar a mano una petición mal formada (vocero):

```bash
curl -i -X POST http://localhost:8000/register -H "Content-Type: application/json" -d '{"mail":'
```
