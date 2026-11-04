-- ==========================================
-- 006_users_foto_perfil.sql
-- ==========================================
-- Agrega la columna para la foto de perfil de usuario, guardada en
-- MinIO (bucket "perfiles") siguiendo el mismo patrón que guiones
-- (bucket "guiones") y fotos de continuidad (bucket "imagenes"): acá
-- solo se guarda la ruta del objeto, nunca el binario.

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS foto_perfil_key text;

COMMIT;
