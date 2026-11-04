-- ==========================================================
-- ELIMINAR TABLAS Y COLUMNA SIN NINGÚN USO EN EL CÓDIGO
-- ==========================================================
-- Auditado contra TODO el backend (modelos, schemas, controllers,
-- routes) y TODO el frontend Flutter antes de escribir este archivo:
-- ninguna de las 3 cosas de abajo se lee ni se escribe en ningún lado
-- ya (ver commits que acompañan esta migración, que quitan las
-- últimas referencias en código antes de este DROP).
--
-- 1) permisos / rol_has_permisos: tablas completas, leftover del
--    esquema original antes de la reescritura del sistema de
--    permisos. El sistema real es una matriz fija en Python
--    (app/utils/permissions.py, diccionario ROLE_PERMISSIONS), nunca
--    se leyó de estas tablas. rol_has_permisos se borra primero
--    porque tiene FK hacia permisos y roles.
--
-- 2) users.id_project: columna vestigial (sin FK real en la BD, ver
--    comentario histórico en app/models/user_model.py). La membresía
--    real usuario-proyecto SIEMPRE vivió en user_projects — esta
--    columna era una copia suelta que se llenaba al crear/invitar un
--    usuario pero nunca se leía para autorizar nada.
DROP TABLE IF EXISTS rol_has_permisos;
DROP TABLE IF EXISTS permisos;

ALTER TABLE users DROP COLUMN IF EXISTS id_project;
