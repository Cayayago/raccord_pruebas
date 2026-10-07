-- ==========================================
-- 005_minio_archivo_key.sql
-- ==========================================
-- Migra el almacenamiento de PDFs de guiones y fotos de continuidad de
-- BYTEA (guardado directo en Postgres) a MinIO (bucket "guiones" para
-- PDFs, bucket "imagenes" para fotos). En vez de la columna
-- "archivo_contenido" con el binario, ahora se guarda "archivo_key"
-- con la ruta del objeto dentro del bucket correspondiente.
--
-- Se asume arranque "desde cero" en cuanto a archivos ya subidos (no
-- se migran los BYTEA existentes a MinIO) — si tu base de datos tiene
-- guiones o fotos de prueba con archivo cargado, se recomienda volver
-- a subirlos manualmente después de correr esta migración, ya que sus
-- binarios se pierden al borrar la columna.
--
-- Correr con la app detenida (o al menos sin subidas de archivo en
-- curso) para evitar condiciones de carrera con las columnas viejas.

BEGIN;

-- ---------- guiones ----------
ALTER TABLE guiones DROP COLUMN IF EXISTS archivo_contenido;
ALTER TABLE guiones ADD COLUMN IF NOT EXISTS archivo_key text;

-- ---------- fotos_continuidad ----------
-- El modelo (GalleryPhoto.archivo_key) es NOT NULL, así que si ya hay
-- filas con archivo BYTEA (datos de prueba) hay que vaciarlas primero
-- para poder agregar la columna como NOT NULL sin que falle.
TRUNCATE TABLE fotos_continuidad;

ALTER TABLE fotos_continuidad DROP COLUMN IF EXISTS archivo_contenido;
ALTER TABLE fotos_continuidad ADD COLUMN IF NOT EXISTS archivo_key text NOT NULL;

COMMIT;
