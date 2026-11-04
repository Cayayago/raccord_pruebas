-- ==========================================
-- 008_reset_datos_contenido.sql
-- ==========================================
-- Vacía TODAS las tablas de contenido/cuentas de la base de datos,
-- dejando intactas SOLO las de configuración del sistema:
-- departamentos, roles, permisos y rol_has_permisos.
--
-- ADVERTENCIA — ES DESTRUCTIVO E IRREVERSIBLE:
--   - Se borran TODOS los usuarios (incluida tu propia cuenta). Después
--     de correr esto vas a tener que registrarte de nuevo desde
--     /register (el registro es público, no requiere sesión).
--   - Se borran clientes, proyectos, guiones, escenas, personajes,
--     actores, plan de rodaje, desglose y fotos de continuidad.
--   - Los archivos binarios (PDFs de guiones, fotos de continuidad) NO
--     se borran de MinIO con este script — solo se borran las filas de
--     la base de datos que apuntaban a ellos (archivo_key). Si quieres
--     limpiar también los objetos en MinIO, hazlo aparte desde la
--     consola web de MinIO (puerto 9001) o con el cliente "mc".
--
-- NO toca: departamentos, roles, permisos, rol_has_permisos (aunque
-- las dos últimas están vacías/sin uso real en el código — ver nota al
-- final del archivo — se conservan porque así lo pediste).

BEGIN;

TRUNCATE TABLE
    users,
    clients,
    projects,
    user_projects,
    guiones,
    escenas,
    escenas_personajes,
    personajes,
    actors,
    plan_rodaje,
    desgloses,
    desglose_items,
    desglose_item_detalle,
    fotos_continuidad
RESTART IDENTITY CASCADE;

-- RESTART IDENTITY reinicia automáticamente las secuencias que están
-- "OWNED BY" una columna (clients.id_cliente, guiones.id_guion,
-- fotos_continuidad.id_foto, user_projects.id, users.id_user,
-- desglose_items.id_desglose_item, desglose_item_detalle.id_detalle).
-- Las secuencias que se usan a mano dentro de triggers/DEFAULT (no
-- están "OWNED BY" ninguna columna) hay que reiniciarlas aparte para
-- que los IDs con prefijo (esc001, act1, rod..., etc.) también
-- arranquen de nuevo desde el principio:
ALTER SEQUENCE actor_seq RESTART WITH 1;
ALTER SEQUENCE escena_seq RESTART WITH 1;
ALTER SEQUENCE personajes_seq RESTART WITH 1;
ALTER SEQUENCE plan_rodaje_seq RESTART WITH 1;
ALTER SEQUENCE desglose_seq RESTART WITH 1;
ALTER SEQUENCE project_seq RESTART WITH 1;

COMMIT;

-- ==========================================
-- Nota sobre "columnas obsoletas"
-- ==========================================
-- Se auditó cada columna de las 18 tablas contra el código del backend
-- (modelos, schemas, controllers, routes montados en main.py) y del
-- frontend Flutter. Resultado: NO se encontraron columnas sueltas sin
-- uso en ninguna tabla — todo lo que existe en escenas, guiones,
-- personajes, actors, plan_rodaje, desgloses, desglose_items,
-- desglose_item_detalle, fotos_continuidad, clients, projects,
-- user_projects y users está leído/escrito en algún controller
-- conectado a una ruta activa.
--
-- Lo único realmente "muerto" en el código son las tablas COMPLETAS
-- "permisos" y "rol_has_permisos": no existe ningún modelo SQLAlchemy,
-- schema, controller o ruta que las lea o escriba — el sistema de
-- permisos real es una matriz fija en Python
-- (app/utils/permissions.py, diccionario ROLE_PERMISSIONS), no la base
-- de datos. No se tocan estas tablas porque se pidió conservarlas.
