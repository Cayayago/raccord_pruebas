-- ==========================================
-- 010_fix_nullable_registro.sql
-- ==========================================
-- Ajustes puntuales sobre el esquema recién migrado a UUID (009):
--
-- 1) clients.telephone quedó NOT NULL, pero el formulario de registro
--    ya no pide teléfono de la empresa (RegisterSchema.telephone es
--    opcional) — el registro fallaba con "Error al registrar" por
--    violar esa restricción.
--
-- 2) users.id_departamento / users.id_project quedaron NOT NULL, pero
--    un usuario recién registrado (POST /register) todavía no tiene
--    departamento ni proyecto asignado — mismo problema.
--
-- Ambas columnas eran nullable en el esquema original (antes de la
-- migración a UUID); esto solo corrige un desajuste que se coló al
-- recrear las tablas.

BEGIN;

ALTER TABLE clients ALTER COLUMN telephone DROP NOT NULL;
ALTER TABLE users ALTER COLUMN id_departamento DROP NOT NULL;
ALTER TABLE users ALTER COLUMN id_project DROP NOT NULL;

COMMIT;
