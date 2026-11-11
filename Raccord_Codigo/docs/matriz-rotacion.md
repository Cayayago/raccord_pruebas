# Matriz de rotación de capas

> Copia este archivo en tu repo como `docs/matriz-rotacion.md` y llénalo al inicio de cada semana.

**Grupo**: Raccord · **Ficha**: 3228973 A · **Stack**: Flutter + FastAPI + PostgreSQL

Capas: **Front** (Flutter) · **API** (FastAPI) · **BD** (integración) · **E2E** (Playwright)

Reglas:

- Cada semana cambias de capa. No repites capa hasta haber pasado por las cuatro.
- En la columna escribe la capa y, al cerrar la semana, el enlace a tu PR de tests.
- Quien revisa tu PR debe haber trabajado en otra capa esa semana.

| Integrante (usuario GitHub) | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 |
|---|---|---|---|---|---|---|---|---|---|
| Javier Yaya (@Cayayago) | E2E — login, sesión, notificaciones, papelera, Crew List, humo UI | API + Front + CI — `PRUEBAS_SEMANA_2.md` | | | | | | | |
| Deiver Algecira (@deiveralgecira03-tech) | E2E — registro de empresa (`tests/api/registro.spec.ts`, `tests/ui/registro.spec.ts`) | API — reparto, subida de fotos, accesos por módulo, contrato momento del día | | | | | | | |

## Cobertura semanal

Anota la cobertura real al cerrar cada semana. El umbral de la semana siguiente es el mayor entre el piso del plan y este valor, redondeado hacia abajo.

| Semana | Frontend (%) | Backend (%) | Umbral configurado para la semana siguiente |
|---|---|---|---|
| S1 (línea base) | 52.9 (18/34 líneas; solo archivos importados por el test) | 48 (solo archivos importados por `test_smoke`) | Frontend 52 · Backend 48 |
| S2 | _anotar tras correr `flutter test --coverage`_ | 35.42 (todo `app/`, 4 074 sentencias) | Backend 35 (`pyproject.toml`) · S3: max(40, real) |

> Desde la S2 el backend mide **todo** `app/`; la cifra de la S1 solo contaba los archivos importados y no es comparable. Por eso el umbral pasa de 48 a 35: no es que la cobertura bajara, es que ahora se mide bien.

## Registro de vocero aleatorio

El vocero escribe su respuesta **antes** de que el instructor llegue a la mesa; el instructor la verifica con una pregunta corta y anota el resultado.

| Semana | Vocero | Capa preguntada | Respuesta escrita | Resultado (Alto / Medio / Bajo) |
|---|---|---|---|---|
| S1 | | | | |

## Hallazgos encontrados por los tests

| Semana | Hallazgo | Test que lo detecta | Estado |
|---|---|---|---|
| S1 | La política de contraseñas (RF-006: mayúscula, minúscula, número y carácter especial) solo se valida en la app Flutter: la API registra `12345678`. | `e2e/tests/api/registro.spec.ts` (marcado `test.fail`) | Abierto |
| S2 | Con `pypdf` 7 la marca de agua fallaba y el guion se descargaba **sin marca de agua** (el error se atrapaba en silencio). | `tests/test_mail_watermark.py` (3 en rojo) | Corregido en `app/utils/watermark.py` |
| S2 | El parser guarda `dia/noche` y `amanecer/dia`, pero `SceneSchema` no los acepta: esas escenas no se pueden editar (422). | `tests/test_contrato_momento_dia.py` (xfail) | Abierto |
| S2 | La API y la app aceptan `anochecer`, pero el ENUM `momentodia` de PostgreSQL no: guardar da 500. | `tests/test_contrato_momento_dia.py` (xfail) | Abierto |

## Regla de rama

- [ ] Ruleset `main protegida` (Settings → Rules → Rulesets) con los checks `backend-fastapi` y `frontend-flutter`.
