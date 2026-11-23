# Pruebas — Semana 5 (Dobles de prueba)

Tema: reemplazar lo que el proyecto no controla (correo, almacenamiento, la hora, el backend visto desde el frontend) por dobles, y probar que la app resiste cuando eso falla. Piso de cobertura al cerrar: **60 %** en frontend y backend.

## Inventario de dependencias externas

| Dependencia | Dónde se usa | ¿Interfaz propia? | Qué pasa si falla |
|---|---|---|---|
| Correo SMTP (Gmail) | `app/utils/mail.py`: recuperación de contraseña, 2FA, invitaciones, bienvenida, contacto | **Sí para recuperación** (`app/utils/notifier.py`, esta semana). Las demás llaman a `mail.py` directo | Recuperación: `MAIL_ERROR` (probado). Registro: el correo de bienvenida va en `try` |
| Almacenamiento MinIO | `app/utils/minio_client.py`: fotos de galería, guiones, foto de perfil | No (se usa el cliente de MinIO directo) | Sin probar todavía |
| La hora actual | Código de recuperación (15 min), código 2FA, expiración del JWT, rate limit | **Sí para recuperación** (`now` como parámetro) | Vencimiento probado en el límite exacto |
| PostgreSQL | Todos los endpoints | `get_db` (se reemplaza por `FakeSession` desde la S4) | — |
| El backend, visto desde Flutter | `lib/core/api_client.dart` | `http.Client` inyectable (`AuthSession(httpClient:)`) | Probado con `MockClient` en la S4 (401/422/502) |

## Deiver — capa API: el correo de recuperación y el reloj

Archivo: `raccord_backend/api_usuarios/tests/test_dobles_correo.py` (10 tests).

**Interfaz propia.** El controlador ya no llama a `send_recovery_email` (que usa `smtplib`) directo: recibe un `Notifier` (`app/utils/notifier.py`). En producción, FastAPI entrega `SmtpNotifier` con `Depends(get_notifier)`; en los tests se reemplaza `Notifier`, nunca `smtplib`. El reloj entra igual: `recover_password(..., now=...)` y `reset_password(..., now=...)`, con `datetime.now` por defecto.

| Test | Doble | Verifica |
|---|---|---|
| `test_recover_sends_the_stored_code_once_to_the_user` | Spy (`mocker.Mock`) | **Comportamiento**: una sola llamada, al correo del usuario, con el mismo código guardado |
| `test_recover_does_not_send_mail_when_user_does_not_exist` | Spy | **Comportamiento**: `assert_not_called()` si el correo no está registrado |
| `test_recover_stores_a_six_digit_code_that_expires_in_15_minutes` | Fake (`NotificadorEnMemoria`) + stub del reloj | **Estado**: código de 6 dígitos, vence a las 10:15, quedó en la bandeja |
| `test_recover_answers_mail_error_instead_of_500_when_smtp_raises` | Stub que lanza `ConnectionRefusedError` | Resiliencia: `MAIL_ERROR`, se registra en el log, el código no queda vigente |
| `test_recover_answers_mail_error_when_notifier_returns_false` | Stub que devuelve `False` | Resiliencia: `MAIL_ERROR` |
| `test_recover_endpoint_responds_json_not_500_when_mail_fails` | Stub inyectado con `dependency_overrides[get_notifier]` | El endpoint real responde 200 JSON y no 500 con el SMTP caído |
| `test_reset_respects_the_15_minute_limit` (×3) | Stub del reloj | Valores límite: 14:59 sirve, 15:00 sirve, 15:01 `CODE_EXPIRED` y la contraseña no cambia |
| `test_smtp_notifier_delegates_to_the_mail_module` | Mock de nuestro módulo `mail` | El adaptador real pasa los datos tal cual |

¿Qué pasaría con la dependencia real? Cada test mandaría un correo de verdad por Gmail (con credenciales en el CI), tardaría segundos, fallaría sin internet y no habría forma de provocar "SMTP caído" a voluntad. Para el reloj habría que esperar 15 minutos.

### Hallazgo (corregido esta semana)

Antes, si el SMTP lanzaba una excepción el endpoint respondía **500**, y si el correo no salía el código **quedaba vigente** aunque el usuario nunca lo recibió. Ahora: `try/except` con `logger.warning`, respuesta `MAIL_ERROR` y se borra el código.

### Mutantes (todos detectados)

| Mutación en `password_controller.py` | Test que la detecta |
|---|---|
| Quitar el `try/except` del envío | `…_instead_of_500_when_smtp_raises` y `…endpoint_responds_json_not_500…` |
| No llamar al notificador (`enviado = True`) | 8 de 10, empezando por `…sends_the_stored_code_once…` |
| Mandar un código distinto al guardado | `…sends_the_stored_code_once…`, el fake y el límite de 15 min |
| `now() > expira` cambiado por `>=` | `test_reset_respects_the_15_minute_limit[15:00]` |
| No borrar el código cuando el correo falla | Los dos tests de `MAIL_ERROR` |

Mutación que **no** se detectaría (para el vocero): cambiar el texto `"Error al enviar correo"`; ningún test compara el mensaje, solo el código `MAIL_ERROR`.

### Revisión de exceso de mocks (propuesta para el grupo)

`test_smtp_notifier_delegates_to_the_mail_module` es el más cercano a "solo verificar el mock": se deja porque el adaptador no tiene otra lógica, pero no se agregan más de ese estilo. Los demás verifican la respuesta del API o lo que quedó guardado, no solo el doble.

## Javier — capa E2E: estados difíciles con `page.route`

Archivo: `e2e/tests/ui/estados-dificiles.spec.ts` (4 tests). La app Flutter corre de verdad en el navegador; `page.route` intercepta la petición **antes** de que salga y responde lo que el test decida.

| Test | Doble | Verifica |
|---|---|---|
| `API caído: avisa que no hay conexión, no intenta el login y no entra` | Stub de falla (`route.abort`) + Spy (contador de llamadas) | **Comportamiento**: se intentó el chequeo una vez y `/users/login` nunca. **Estado**: sigue en el login |
| `500 sin JSON: muestra el código HTTP…` | Stub (`route.fulfill` con HTML) | Mensaje `Error de conexión con el servidor (500)` y no entra |
| `422 de validación: muestra el mensaje del campo…` | Stub con la forma de Pydantic | Se ve el `msg` del primer error y no el JSON crudo |
| `lista vacía: una persona sin proyectos ve el aviso…` | Stubs del login + Spy de `/users/*/projects` | **Estado**: llega a `#/proyectos` y muestra `Todavía no tienes proyectos asignados.`. **Comportamiento**: pidió la lista una sola vez |

¿Qué pasaría con el backend real? No hay forma de tumbar el API a voluntad, ni de que devuelva un 500 sin JSON, ni de garantizar un usuario sin proyectos sin tocar la base de datos de pruebas.

Resultado: 4 de 4 en verde, y 12 de 12 con `--repeat-each=3` (`pnpm exec playwright test --project=ui estados-dificiles`). No necesitan backend: solo el frontend en `localhost:8081`.

### Observaciones

- **El helper `campo(page, 'E-mail')` de `tests/ui/flutter.ts` quedó desactualizado.** Flutter ahora nombra el campo por su hint (`Ingresa tu correo`) y la etiqueta queda como texto suelto, así que el `getByRole('group', { name: 'E-mail' })` ya no lo encuentra. Estos tests localizan los campos por su nombre actual y no tocan el helper compartido.
- **`fill` no es confiable con los campos de Flutter:** a veces el texto no llega al controlador y el formulario se frena en la validación local. Los tests hacen clic y escriben con el teclado.
- **La app pide `GET /users/{id}/projects` dos veces al entrar a Proyectos.** El test solo verifica que todas las llamadas vayan a la URL del usuario correcto y no fija el número. Queda para revisar si es una petición repetida innecesaria.

## Cómo correrlo

```bash
cd Raccord_Codigo/raccord_backend/api_usuarios
pip install -r requirements-dev.txt          # ahora incluye pytest-mock
python -m pytest tests/test_dobles_correo.py -v --no-cov
python -m pytest                             # todo, con cobertura
```
