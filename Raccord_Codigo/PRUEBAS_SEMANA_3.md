# Pruebas — Semana 3 (componentes)

Tema común: **Front** para todo el grupo. Piso de cobertura al cerrar: **40 %** en frontend y backend.

El reto del bootcamp está escrito para React Testing Library; Raccord es Flutter, así que se usan los **widget tests** de `flutter_test`:

| Reto (React) | Raccord (Flutter) |
|---|---|
| `render` | `tester.pumpWidget` |
| `getByRole` / `getByLabelText` | `find.text`, `find.widgetWithText(ElevatedButton, 'Ingresar')`, `campo('E-mail')` (busca el campo por su etiqueta visible) |
| `user-event` | `tester.enterText`, `tester.tap` |
| `findBy` (esperar) | `await tester.pumpAndSettle()` y luego `find...` |
| `queryBy` (ausencia) | `expect(find..., findsNothing)` |
| `renderWithProviders` | `test/helpers/pump_with_providers.dart` (compartido) |
| `vi.mock` del cliente HTTP | `MockClient` de `package:http/testing.dart` inyectado en `AuthSession` |

## Front: LoginRegisterScreen (Deiver)

Archivo: `raccord_flutter/test/screens/login_register_screen_test.dart` (10 tests).

| Test | Qué verifica | Tipo |
|---|---|---|
| campos vacíos | aparecen "Ingresa tu correo" / "Ingresa tu contraseña" y **no** se llama a la API | interacción + validación |
| credenciales incorrectas | se muestra el mensaje del backend, no navega, no queda sesión | interacción + error |
| credenciales correctas | guarda la sesión y navega a `/proyectos`; llama a `/users/2fa/check` y `/users/login` en ese orden | interacción + asíncrono |
| 2FA requerido | envía el código y navega a `/2fa` | interacción |
| correo en minúscula | lo escrito en E-mail se guarda en minúscula | interacción |
| registro vacío | botón Registrar deshabilitado y explica qué falta | estado |
| contraseña débil | dice exactamente qué reglas faltan | validación |
| contraseñas distintas | "Las contraseñas no coinciden." | validación |
| términos sin aceptar | no deja registrar | validación |
| registro completo | registra, inicia sesión y navega a `/registrar-proyecto` | interacción + asíncrono |

**Mutante propuesto** (lo corre y documenta Deiver en su PR):

| Mutante | Test que debe fallar |
|---|---|
| En `login_register_screen.dart`, validador del E-mail → `validator: (v) => null,` | `con los campos vacíos muestra la validación y no llama a la API` |

## Backend al 40 % (responsable de la semana)

Archivo: `raccord_backend/api_usuarios/tests/test_controladores_contenido.py` (38 tests).

- Escenas: no se crean sin guion, no se mueven a un guion de **otro proyecto** (`CROSS_PROJECT_MOVE`), la edición parcial solo cambia lo enviado, el listado trae el reparto de cada escena.
- Personajes: no se eliminan si tienen actores (`CHARACTER_HAS_ACTORS`); al eliminar se informa de cuántas escenas se quitó.
- Plan de rodaje: un día con escenas agendadas no se elimina (`SHOOTING_DAY_IN_USE`); se crea activo por defecto.

Mutantes comprobados (todos detectados):

| Mutante | Test que lo detectó |
|---|---|
| `scene_controller`: quitar `if proyecto_nuevo != proyecto_actual` | `test_update_scene_full_rejects_cross_project_move_too` |
| `character_controller`: `actors_count > 0` → `> 1` | `test_delete_character_is_blocked_when_it_has_actors` |
| `shooting_day_controller`: `scenes_count > 0` → `< 0` | `test_delete_shooting_day_is_blocked_when_it_has_scenes` |

## Cobertura y umbrales

| Parte | Cobertura real | Umbral nuevo |
|---|---|---|
| Frontend | 49,62 % | 49 (`raccord_flutter/coverage_threshold.txt`) |
| Backend | 41,29 % | 41 (`pyproject.toml`, `fail_under`) |

> El frontend mide solo los archivos que cargan los tests (así lo calcula `flutter test --coverage`). Por eso bajó de 75 % a 49,62 %: al probar una pantalla completa entran más archivos al cálculo, no es que se haya probado menos.

## Cómo correrlo

```bash
cd Raccord_Codigo/raccord_flutter
flutter test test/screens/login_register_screen_test.dart
flutter test --coverage

cd ../raccord_backend/api_usuarios
python -m pytest
```
