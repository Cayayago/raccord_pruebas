# Pruebas — Semana 6 (integración con BD real)

Rama: `test/semana-06`. Capa de Javier: **API** contra PostgreSQL real. La capa **BD** queda para Deiver (ver `docs/matriz-rotacion.md`).

## 1. Entorno de integración

- `docker-compose.test.yml`: PostgreSQL 18 desechable, proyecto propio (`raccord-test`), puerto **5433**, BD `raccord_test`. No toca la BD de desarrollo.
- El esquema se crea aplicando en orden las migraciones de producción `sql/0*.sql` (`tests/db/init-esquema.sh`), no un esquema inventado para pruebas.
- Los tests reciben la conexión **solo** por `DATABASE_URL`. Sin esa variable se saltan (el CI sin BD sigue verde). Si el nombre de la BD no termina en `_test`, el fixture falla: nunca corre contra desarrollo.
- Limpieza: **rollback**. `db_session` abre una transacción por test y usa `join_transaction_mode="create_savepoint"`, así los `commit()` del código bajo prueba se convierten en savepoints y se deshacen al final. Cada test crea sus propios datos (cliente, usuario, proyecto, vínculo, token).
- Comandos: ver `README.md`, sección 9.

## 2. Tests de integración (capa API)

`tests/integracion/test_api_personajes_bd.py` — `POST /characters` con rutas, permisos por proyecto, JWT y restricciones reales:

| Test | Qué comprueba |
|---|---|
| crear personaje | 200, el `id_personaje` generado por la BD es un UUID válido y la fila queda guardada con los valores enviados |
| usuario de solo lectura | 403 y no se inserta nada |
| `id_project` que no es UUID | 4xx, no 500 |
| `edad` fuera del rango de `integer` | 4xx, no 500, y no se inserta nada |

`tests/integracion/test_bd_de_pruebas.py` valida el entorno (roles 1001-1005, BD vacía al inicio, un `commit` del test no sobrevive al siguiente).

## 3. Hallazgos

| # | Hallazgo | Causa | Corrección |
|---|---|---|---|
| 1 | La BD de pruebas no se creaba: la migración `011` fallaba (`column id_client ... already exists`) | No era idempotente; `000` ya incluía la columna | `ADD COLUMN IF NOT EXISTS` en `011_users_id_client.sql` |
| 2 | El repo de pruebas tenía migraciones solo hasta la 027; el producto va por la 034 | Modelos como `UserProject.estado` o `Project.estado` dependen de 028/029 | Se copiaron `028`–`034` a `sql/` |
| 3 | `POST /characters` con `id_project: "abc"` → **500** | PostgreSQL rechaza el cast a `uuid` (`DataError`) y nadie lo capturaba | `CharacterSchema` valida que `id_project` sea UUID → 422 |
| 4 | `POST /characters` con `edad: 3000000000` → **500** | Pasa el `int` de Python pero desborda el `integer` de PostgreSQL (`integer out of range`) | `edad` limitada a 0–120 (crear y actualizar) → 422 |

Los hallazgos 3 y 4 solo aparecieron con la BD real: el `FakeSession` de las semanas anteriores no valida tipos ni rangos.
Cada uno tiene su prueba unitaria en el valor límite: `tests/test_hallazgos_semana6.py` (0, 120, 121, 3 000 000 000; `"abc"`, `""`, `"1111"`, UUID + `x`).

Observación fuera de alcance: `Genero = Literal["masculino", "fenemino", "otro"]` en `actor_schema.py` (probable error de ortografía de "femenino"). No se cambió porque el frontend podría depender de ese valor; queda para revisión.

## 4. Mutantes

Se rompió a propósito cada regla nueva y se corrió `tests/test_hallazgos_semana6.py`:

| Mutante | Resultado |
|---|---|
| `EDAD_MAX = 3_000_000_000` | **detectado** (1 test falla: `edad=3000000000` ya no se rechaza) |
| `validar_uuid` acepta cualquier texto (`UUID(...)` → `pass`) | **detectado** (4 tests fallan) |

## 5. PostgreSQL frente a MySQL

El curso usa MySQL; el proyecto usa PostgreSQL. Diferencias que aparecieron:

- `uuid` es un tipo real: un texto inválido falla en la BD (hallazgo 3). MySQL lo guardaría como texto.
- `integer` es estricto: un valor fuera de 4 bytes da error (hallazgo 4); según el modo, MySQL puede truncar en silencio.
- Los ids autogenerados (secuencias) **no se deshacen con el rollback**; por eso los tests no dependen de valores de id.
- Funciones/extensiones (`pgcrypto`, `pg_trgm`) vienen en la imagen `postgres:18`; en MySQL no aplican.

## 6. Cobertura

| | Semana 5 | Semana 6 | Umbral |
|---|---|---|---|
| Backend | 64.59 % | **70.35 %** (570 tests) | `fail_under = 70` |
| Frontend | 63.65 % | pendiente (Deiver) | ≥ 70 en `coverage_threshold.txt` |

El backend se mide sin `DATABASE_URL` (los tests de integración no suman a la cobertura). Subida con pruebas de reglas reales: `tests/test_actor_controller.py` (tipo, tamaño y vacío de fotos, borrado de archivos, no encontrado) y `tests/test_breakdown_controller.py` (acceso por departamento, no mover ítems a otro proyecto, pendientes por prioridad).

## 7. Capa BD (Deiver): la tabla `escenas` contra PostgreSQL real

Raccord no tiene capa "repositorio": las consultas viven en `app/controllers/scene_controller.py`, así que ese controlador hace de DAO. Archivo: `tests/integracion/test_bd_escenas.py` (25 tests); reglas unitarias en `tests/test_hallazgos_semana6_bd.py` (40 tests, sin BD).

- **Limpieza:** la misma del grupo, **rollback** (`db_session`). Cada test crea su cliente, proyecto, guion, día de rodaje y desglose con valores únicos (`uuid4`); ningún id fijo.
- **Conexión:** solo por `DATABASE_URL`; sin ella se saltan.

| Qué se prueba | Tests |
|---|---|
| Cada función al menos una vez | crear (fila y defaults en la BD), buscar por id e inexistente, listar por proyecto / guion / día de rodaje / desglose, PATCH parcial, PUT que intenta mover a otro proyecto, borrar |
| Consultas propias | JOIN escenas → guiones para filtrar por proyecto (ignora otro proyecto); reparto embebido desde `escenas_personajes`; filtros por día y desglose; **orden del guion** en las cuatro listas |
| Restricciones de la tabla | `NOT NULL` (número y encabezado), `varchar(45)`, rango de `integer`, FK `escenas_id_rodaje_fkey`, `ON DELETE CASCADE` hacia reparto y fotos (el personaje no se borra), borrar el guion borra sus escenas, versión del guion única **por proyecto** |

### Hallazgos de la capa BD (corregidos)

| # | Hallazgo | Antes | Corrección | Test unitario (límite) |
|---|---|---|---|---|
| 5 | La versión del guion era `UNIQUE` en **toda** la BD, aunque el código decía "única dentro del proyecto": si otra productora ya tenía un "V2", crear el tuyo fallaba | 500 (`UniqueViolation`) | `sql/035_guiones_version_por_proyecto.sql` (idempotente): `UNIQUE (id_project, numero_de_version)`; modelo con `UniqueConstraint`; `create_script` responde `DUPLICATE_VERSION` si la BD frena un duplicado | `test_create_script_rejected_by_the_unique_constraint…` |
| 6 | Las listas de escenas se ordenaban por `id_escena` (UUID aleatorio): el API devolvía "2, 10A, 9, 1, 10". El `FakeSession` ignora el `ORDER BY`; el frontend reordena, por eso nadie lo notó | desorden | `ORDEN_GUION`: parte numérica inicial y luego el texto (1, 1B, 2, 3, 11) | integración (es una regla de SQL) |
| 7 | `POST /scenes` con número de escena de 46 caracteres | 500 (`value too long`) | `max_length=45` | 45 pasa, 46 no |
| 8 | `pagina` (y `dia_dramatico`, `orden_rodaje`, `bloque_grabacion`) = 3 000 000 000 | 500 (`integer out of range`) | `0 ≤ valor ≤ 2 147 483 647` | 0 y 2 147 483 647 pasan; −1 y 2 147 483 648 no |
| 9 | `id_rodaje: "abc"` (igual `id_guion`, `id_desglose`) | 500 (cast a `uuid`) | validación de UUID → 422 | `"abc"`, `""`, `"1111"`, UUID + `x` |
| 10 | `id_rodaje` con formato válido pero inexistente | 500 (FK) | `_guardar()`: rollback y `INVALID_REFERENCE` | sesión fake cuyo `commit` lanza `IntegrityError` |
| 11 | Número de escena vacío y página negativa | se guardaban | `min_length=1`, `ge=0` | `""` y −1 rechazados |

Los tests unitarios de la S3 usaban ids inventados (`"guion-A"`); ahora son UUID fijos (`GUION_A`, …) porque el schema los valida.

### Mutantes de la capa BD

| Mutación | Resultado |
|---|---|
| M1: quitar el `ORDER BY` en `get_scenes` (lista por proyecto) | **Se escapó** al principio: el test del JOIN compara con `sorted()`. Se agregó `test_scenes_by_project_also_come_in_script_order`; ahora las cuatro listas detectan su mutante (el de día de rodaje y desglose se reforzó con 4 escenas, con 2 podía pasar por suerte) |
| M2: quitar el filtro `Script.id_project == id_project` del JOIN | detectado (`…joins_through_the_script_and_ignores_other_projects`) |
| M3: quitar `max_length=45` | detectado (2 de integración + 2 unitarios) |
| M4: no capturar `IntegrityError` al guardar | detectado (`…shooting_day_that_does_not_exist_is_not_a_500` + unitario) |
| M5: limpieza con `commit` en vez de `rollback` | detectado (`test_la_bd_de_pruebas_empieza_sin_usuarios`) y dejó 18 escenas en la BD: por eso la prueba de fuego empieza de cero |

### PostgreSQL frente a MySQL (capa BD)

- Sin `ORDER BY`, ninguno de los dos garantiza orden; con UUID aleatorio como llave el desorden en PostgreSQL es visible al instante.
- `substring(texto, '^[0-9]+')` con expresión regular es de PostgreSQL; en MySQL sería `REGEXP_SUBSTR`.
- `varchar(45)` en PostgreSQL siempre rechaza el valor largo; MySQL sin modo estricto lo **trunca** y guarda.
- Una restricción `UNIQUE` con nombre se cambia con `DROP CONSTRAINT IF EXISTS` y un bloque `DO $$`; MySQL no tiene `IF NOT EXISTS` para constraints.

### Prueba de fuego (en el entorno de Deiver)

BD borrada y recreada con todas las migraciones (incluida la 035) → `pytest tests/integracion` dos veces seguidas: **31 passed / 31 passed**, y al final `escenas`, `guiones` y `projects` quedan en 0 filas. La 035 se corrió dos veces sin error (idempotente).

### Cobertura

Backend sin `DATABASE_URL`: **70,69 %** (611 tests). Frontend: ver la sección de la capa Front de la semana 6/7.

## 8. Pendiente

- Revisión cruzada: Javier revisa la capa BD; Deiver revisa la capa API.
- Prueba de fuego en la máquina de quien **no** montó la BD (con Docker: `down -v`, `up -d --wait`, tests dos veces).
- Frontend ≥ 70 % y su umbral.
