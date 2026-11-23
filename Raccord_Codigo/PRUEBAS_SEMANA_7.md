# Pruebas — Semana 7 (Playwright a fondo)

Rama: `test/semana-07`. Capa de Javier: **E2E**. Flujos críticos elegidos y por qué:

| Flujo | Responsable | Por qué es crítico |
|---|---|---|
| 1. Registro + login | Deiver | Es la puerta de entrada de toda cuenta nueva. |
| 2. **Personajes** | Javier | Es lo que preproducción usa a diario; un personaje que no se guarda, o se guarda dos veces, contamina escenas, actores y desgloses. |
| 3. **Proyecto** (crear y abrir) | Javier | Sin proyecto activo no hay guion, escenas ni personajes; abrir el equivocado es trabajar sobre datos ajenos. |

## 1. Infraestructura E2E

- `playwright.config.js` levanta el backend con `webServer` (uvicorn en 127.0.0.1:8000) contra la BD de pruebas de la S6 (5433) y un MinIO de pruebas (9100). `reuseExistingServer: false`: si el puerto está ocupado, falla en vez de probar sin querer contra el backend de desarrollo.
- Datos por **API** (`tests/support/datos.ts`): cada test crea su empresa, usuario y proyecto con valores únicos (hora + pid + contador). Por la UI solo se prueba el flujo.
- Sesión ya iniciada sin pasar por el login (`tests/support/sesion-ui.ts`): se escriben las claves de `SharedPreferences` en `localStorage` antes de cargar la app. Con `proyecto: null` la persona llega sin proyecto activo.
- `E2E_DISABLE_RATE_LIMIT=true` solo existe en el backend de prueba y apaga el límite por IP y el bloqueo por IP del login (`app/utils/rate_limit.py`, `login_guard.py`). El bloqueo por cuenta sigue activo. Cubierto por `tests/test_modo_e2e.py`.
- Paralelo: sin `workers: 1`. Cada test es independiente, así que no comparten datos.

## 2. Tests

`e2e/tests/ui/personajes.spec.ts`

| Test | Qué comprueba |
|---|---|
| crear por la UI | aparece en la lista y la API lo tiene **una** vez, con el nombre exacto |
| sin nombre | muestra el error y no guarda nada |
| doble clic con red lenta | una sola petición y un solo registro (ver hallazgo 1) |

`e2e/tests/ui/proyectos.spec.ts`

| Test | Qué comprueba |
|---|---|
| elegir un proyecto | abre su dashboard (encabezado con su nombre) y queda como proyecto activo |
| sin nombre | `aria-invalid` en el campo y no se crea nada |
| doble clic con red lenta | una sola petición y un solo proyecto (ver hallazgo 2) |

Aprendizajes de Flutter Web (el árbol de semántica no es el DOM de siempre):

- `fill` no es confiable: el valor llega al `<input>` pero el framework no siempre lo registra. Se escribe con el teclado y se confirma el valor exacto dentro de `toPass` (`tests/support/campos.ts`).
- Las filas de lista son `group` con el texto como nombre accesible; los desplegables son `button` y sus opciones `menuitem`.
- Los mensajes de error salen dos veces (campo y región `aria-live`): se valida `aria-invalid`.
- `campo()` acepta las dos formas de exponer un campo (con y sin `Semantics(label)`), según qué imagen del frontend esté corriendo.

## 3. Hallazgos

1. **Doble envío al guardar un personaje.** Con un doble clic y la red lenta salían dos `POST /characters`: duplicado, y el segundo cierre de diálogo sacaba a la persona al Dashboard. Corregido en `characters_screen.dart` (`if (_loading) return;`).
2. **Doble envío al crear un proyecto.** Mismo patrón aunque el botón se deshabilita: el segundo clic llega antes del redibujado. Corregido en `project_form_screen.dart`.
3. **Intermitencia del propio test.** Con `--repeat-each=5` 1 de 30 falló: dos workers generaban el mismo NIT. Corregido incluyendo el pid.

Los tests de 1 y 2 usan `test.fail()` mientras la imagen del frontend que corre en :8081 no se reconstruya (el repo de pruebas no trae `raccord_flutter/web`). Con `E2E_FRONT_CORREGIDO=true` corren normal y deben pasar.

## 4. Mutante

Se rompió el backend a propósito: `create_character` guardaba `character.nombre.upper()`.

| Mutante | Resultado |
|---|---|
| nombre del personaje en mayúsculas al guardar | **detectado**: `personajes.spec.ts` falla en `expect(await personajesPorApi(nombre)).toBe(1)` (recibe 0) |

Detalle: la fila **sí** se veía en la pantalla (Playwright compara el nombre accesible sin distinguir mayúsculas). Lo atrapó la comprobación contra la API con comparación exacta; por eso el test verifica las dos cosas.

## 5. Estabilidad

| Corrida | Resultado |
|---|---|
| `tests/ui` completo, 6 workers | 17 pasan, 2 omitidos (piden `ADMIN_MAIL`/`ADMIN_PASS`), 2 fallas esperadas |
| `--repeat-each=5` | 29 de 30; 1 intermitencia (hallazgo 3) |
| `--repeat-each=10`, 8 workers | **60 de 60** |

## 6. Cobertura

| | Semana 6 | Semana 7 | Umbral |
|---|---|---|---|
| Backend | 70.35 % | **75.14 %** (641 tests) | `fail_under = 75` |
| Frontend | pendiente | pendiente (Deiver) | ≥ 75 en `coverage_threshold.txt` |

## 7. Pendiente

- Flujo 1 (Deiver): ≥ 2 E2E de registro/login con la base nueva, doble clic en Registrar/Ingresar, mutante propio y frontend ≥ 75 %.
- Reconstruir la imagen del frontend y correr con `E2E_FRONT_CORREGIDO=true`.
- Revisión cruzada de los PR.

Comandos: desde `e2e/`, `pnpm exec playwright test tests/ui`. Requiere `docker compose -f docker-compose.test.yml up -d --wait` y el puerto 8000 libre.
