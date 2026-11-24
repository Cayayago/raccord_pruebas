# Pruebas — Semana 7 (Playwright a fondo)

Rama: `test/semana-07`. Capa de Javier: **E2E**. Flujos críticos elegidos y por qué:

| Flujo | Responsable | Por qué es crítico |
|---|---|---|
| 1. **Registro + login** | Deiver | Es la puerta de entrada de toda cuenta nueva; si falla, nadie empieza a usar Raccord (ver sección 7). |
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

## 7. Flujo 1 — Registro + login (Deiver)

Por qué es crítico: es la puerta de entrada. Si falla, ninguna productora nueva puede empezar a usar Raccord, y si deja entrar con una contraseña equivocada, el acceso queda abierto.

Archivo: `e2e/tests/ui/registro-login.spec.ts`. Objeto de página **sin aserciones**: `e2e/tests/support/pantalla-acceso.ts` (abrir, llenar ingreso, ir a registro, llenar registro, enviar y esperar la respuesta).

| Test | Tipo | Qué comprueba |
|---|---|---|
| registro por la UI | feliz | llega a "Registrar Proyecto" y la cuenta existe de verdad (login por API) |
| registro con un correo que ya existe | error visible | la respuesta es `DUPLICATE_USER`, el mensaje se ve y no navega |
| doble clic en Registrar con la red lenta | Parte 3 | un solo `POST /register` (ver hallazgo 4) |
| login de una cuenta creada por API | feliz | la respuesta es éxito y llega a `#/proyectos` |
| login con la contraseña equivocada | error visible | `INVALID_CREDENTIALS`, el mensaje "Verifica tu correo y tu contraseña…" se ve y no entra |
| doble clic en Ingresar con la red lenta | Parte 3 | un solo `POST /users/login` (ver hallazgo 5) |

- Datos: cada test crea lo que necesita por API (`crearEmpresa`) o con valores únicos (`unico()`); ningún usuario del `.env`.
- Sin `waitForTimeout`: se espera la respuesta del backend (`waitForResponse`) y la navegación con aserciones web-first. La red lenta se simula con `page.route` (+1,5 s al `POST`).
- Locators accesibles: pestañas por `tab`, botones por `button`, casilla por `checkbox`. Los campos del registro van **por posición**: en el build web varios no exponen la etiqueta como grupo y su nombre accesible es el hint, que desaparece al escribir; por etiqueta, "Email Empresa" resolvía también "Nº Documento". El formulario no tiene campos condicionales.
- Flutter Web a veces pierde el texto de un campo cuando el foco no alcanza a moverse (se vio "Apellidos" vacío y Registrar deshabilitado). El objeto de página confirma **todo** el formulario al final y reescribe lo que falte, dentro de `toPass`.
- Razón social, nombres y apellidos se escriben en minúsculas: el formulario usa `LowerCaseTextFormatter`.

### E2E en el CI (adelanto de la semana 8)

`.github/workflows/e2e.yml` corre el flujo en cada PR que toque `e2e/`, el frontend o el backend:

1. PostgreSQL 18 de pruebas (5433) con el esquema de las migraciones `sql/0*.sql`.
2. El frontend compilado para web **desde el mismo commit** (`flutter create --platforms=web` genera la plantilla `web/` que el repo no trae) y servido en :8081. Así un arreglo en la app se prueba en el mismo PR, sin reconstruir la imagen Docker (lo que obligaba a usar `test.fail()` en los hallazgos 1 y 2).
3. Playwright arranca el backend con el `webServer` de `playwright.config.js`.
4. `--repeat-each=5 --retries=0`: un test intermitente falla en vez de esconderse tras un reintento. Si algo falla, el job imprime el árbol de accesibilidad del momento del fallo.

### Hallazgos (Parte 3)

4. **Doble envío al registrarse.** Con doble clic y la respuesta retrasada 1,5 s salían dos `POST /register`; el segundo respondía "La empresa ya está registrada" mientras el primero ya había navegado. **5 de 5 en rojo** antes del arreglo.
5. **Doble envío al iniciar sesión.** Dos `POST /users/login` (y dos `/users/2fa/check`). **5 de 5 en rojo** antes del arreglo.

Corrección para los dos: `if (_loading) return;` al inicio de `_submit` en `login_register_screen.dart` (el mismo patrón que Javier corrigió en personajes y proyectos). Después: **5 de 5 en verde**.

Red lenta: con 1,5 s de retraso en login y registro no se perdió nada; el botón muestra el indicador de carga y la app navega al llegar la respuesta.

### Mutante

Se rompió el flujo en la app: en el login, el `catch (ApiException)` dejó de mostrar el mensaje (`_showError(e.message)` → `debugPrint(e.message)`). Se corrió en el CI con un commit aparte y se revirtió en el siguiente.

| Mutante | Resultado |
|---|---|
| el login no muestra el error del backend | **detectado 5 de 5** por "login con la contraseña equivocada": `expect(getByText(/Verifica tu correo y tu contraseña/)).toBeVisible()` → *element(s) not found*. Los otros 25 pasaron: solo ese test mira el mensaje, por eso verifica además el código `INVALID_CREDENTIALS` de la respuesta |

### Estabilidad

| Corrida (CI, 2 workers) | Resultado |
|---|---|
| Primeras corridas | revelaron los 3 problemas del test (campo ambiguo, minúsculas, campo que perdía el texto), no de la app |
| Antes del arreglo, `--repeat-each=5` | 20/20 de los 4 tests funcionales; 10/10 en rojo los de doble clic (los hallazgos) |
| Después del arreglo, `--repeat-each=5 --retries=0` | **30 de 30** |

### Cobertura

Frontend **79,79 %** (161 tests; umbral 79). Al juntar la S6 con la S7 el frontend quedó en 76,00 % exacto, sin margen, porque la S7 trae código nuevo de la app; se agregó `test/widgets/invite_person_dialog_test.dart` (validación, envío, error del backend y cancelar). Backend **75,44 %** con la capa BD de la S6 incluida (umbral 75). Los dos pasan el piso de la semana.

## 8. Pendiente

- Reconstruir la imagen del frontend y correr personajes y proyectos con `E2E_FRONT_CORREGIDO=true`, o sumarlos al workflow E2E (ya compila el frontend desde el commit).
- Suite completa en paralelo con `--repeat-each=5` (Parte 4) cuando los tres flujos estén en `main`.
- Revisión cruzada de los PR.
