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

## 7. Pendiente

- Capa BD (Deiver): ≥ 3 tests, hallazgos y mutante propios; revisión cruzada del PR.
- Frontend ≥ 70 % y su umbral.
- Prueba de fuego en la máquina de Deiver: `down -v`, `up -d --wait`, tests dos veces seguidas.
- Fila de la semana 6 en `docs/matriz-rotacion.md`.
