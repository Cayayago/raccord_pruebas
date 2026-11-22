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

## Javier — ángulo BD: respuestas que dependen de lo guardado

Archivo: `raccord_backend/api_usuarios/tests/test_api_bd.py` (25 tests). Misma técnica que el ángulo E2E: `TestClient` sobre la app real y `FakeSession`; cada test decide qué "hay guardado" y verifica la respuesta HTTP **y** lo que el endpoint le pidió a la BD (`api.db.deleted`, `api.db.commits`).

Cambio en `tests/fakes.py`: `FakeQuery` ahora entiende `.offset()` y `.limit()` y corta la lista como lo haría la BD, para poder probar qué página devuelve la búsqueda de fotos. Sigue ignorando los filtros SQL (eso es de la semana 6).

| Grupo | Escenario | Esperado |
|---|---|---|
| Dependientes | `DELETE /characters/{id}` con 2 actores | `200` JSON, `success: false`, `CHARACTER_HAS_ACTORS`, **no** se borra ni se hace commit |
| Dependientes | `DELETE /characters/{id}` sin actores y en 3 escenas | se borra, el mensaje avisa de las 3 escenas |
| Dependientes | `DELETE /shooting-days/{id}` con 2 escenas agendadas | `SHOOTING_DAY_IN_USE`, no se borra |
| Dependientes | `DELETE /shooting-days/{id}` sin escenas | se borra |
| Inexistente | `DELETE /characters/no-existe` | `404` JSON `{"detail": "Personaje no encontrado"}` |
| Relación | `GET /shooting-days/{id}` | trae las escenas de ese día (y `[]`, no `null`, si no hay) |
| Búsqueda | `GET /fotos/project/{id}/buscar?page=2&page_size=2` con 5 fotos | items de la página 2, `total 5`, `total_pages 3` |
| Búsqueda | proyecto sin fotos / `page_size=5000` / `page=0` | página vacía / tope de 200 / página 1 |
| Búsqueda | `desde=ayer` / `page=dos` | `INVALID_DATE` en el sobre / `422` sin repetir el valor |
| Papelera | `DELETE /fotos/{id}` (Onset) | la fila **no** se borra: `eliminada`, fecha y quién lo hizo |
| Papelera | restaurar una foto que no está en la papelera / una que sí | `NOT_DELETED` / vuelve a la galería |
| Papelera | papelera con rol Usuario / con Director / restaurar como Administrador | `403` / solo lo eliminado / `403` |
| Papelera | `DELETE /fotos/{id}/definitivo` | pide a MinIO borrar el archivo **y** borra la fila |
| Columnas | personaje con nombre de 46 / código de 31 caracteres (POST y PATCH) | `422` con el campo que falla; 45 y 30 caben justo |

### Hallazgo (corregido esta semana)

> 🔎 **Hallazgo:** `personajes.nombre` es `varchar(45)` y `codigo_personaje` `varchar(30)`, pero `CharacterSchema` no limitaba la longitud. Un nombre de 46 caracteres pasaba la validación del API, PostgreSQL lo rechazaba al guardar (*value too long*) y la persona recibía un `500` genérico, sin saber qué campo estaba mal. **Corregido** en `character_schema.py`: `max_length` igual al de la columna, así que ahora responde `422` con `loc: ["body", "nombre"]`. Tests: `test_create_character_with_a_name_longer_than_the_column_responds_422`, `…code_longer…`, `…patch…` y `test_character_schema_limits_match_the_database_columns` (si cambia la columna, el schema debe cambiar con ella). Antes de corregir, los 3 primeros estaban en rojo y el de los valores límite (45 y 30) en verde.

### Observaciones (no son defectos corregidos esta semana)

- Los bloqueos de negocio (`CHARACTER_HAS_ACTORS`, `SHOOTING_DAY_IN_USE`, `NOT_DELETED`, `INVALID_DATE`) responden **HTTP 200** con `success: false`. Es el contrato que usa el frontend (`api_client.dart` lanza `ApiException` cuando `success == false`), así que los tests lo fijan tal cual; cambiarlo a `409` exigiría cambiar también el cliente.
- `personajes.codigo_personaje` no es único: dos personajes del mismo proyecto pueden compartir código. El frontend usa ese código para asociar fotos (`personaje_codigo`). Pendiente de decidir con el grupo si se agrega una restricción única por proyecto.
- `DELETE /fotos/{id}/definitivo` no exige que la foto esté en la papelera (el comentario del controlador lo deja así a propósito).

### Mutantes (todos detectados)

| Mutante | Test que lo detectó |
|---|---|
| `gallery_photo_controller.restore_photo`: `if not photo.eliminada:` → `if False:` | `test_restoring_a_photo_that_is_not_in_the_recycle_bin_is_rejected` |
| `gallery_photo_controller.delete_photo`: quitar `photo.eliminada = True` | `test_deleting_a_photo_moves_it_to_the_recycle_bin_without_deleting_the_row` |
| `gallery_photo_controller.search_photos`: quitar el tope `min(page_size, MAX_PAGE_SIZE)` | `test_photo_search_caps_the_page_size_at_200` |
| `shooting_day_controller.delete_shooting_day`: `scenes_count > 0` → `> 5` | `test_delete_shooting_day_with_scheduled_scenes_is_blocked` |
| `permissions.py`: `manage_recycle_bin` del Administrador → `True` | `test_administrator_can_view_but_not_manage_the_recycle_bin` |
| `character_schema.py`: quitar `max_length` | los 3 tests de longitud (estaban en rojo antes de la corrección) |

### Cobertura de cierre con mis tests

Backend: **63,91 %** (498 tests; antes 62,70 %). Umbral `fail_under` 62 → **63**.

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
