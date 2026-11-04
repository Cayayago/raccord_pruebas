-- ==========================================
-- MODULO: GUIONES - PDF REAL EN BASE DE DATOS
-- ==========================================
-- Antes, "archivo" era solo un campo de texto libre (nombre/URL) que no
-- guardaba ningún archivo de verdad. Ahora el PDF se sube con
-- POST /scripts/{id}/archivo y se guarda directo en la base de datos
-- (columna BYTEA archivo_contenido), y se visualiza/descarga con
-- GET /scripts/{id}/archivo.
--
-- "archivo" (texto) se deja nullable por compatibilidad con filas que
-- ya existan, pero deja de ser obligatorio al crear un guion.
--
-- Corre este script contra tu Postgres real antes de probar la carga
-- de PDF (subir un guion nuevo o abrir uno existente y adjuntarle un
-- archivo).

ALTER TABLE guiones
    ALTER COLUMN archivo DROP NOT NULL;

ALTER TABLE guiones
    ADD COLUMN IF NOT EXISTS archivo_nombre   VARCHAR(255),
    ADD COLUMN IF NOT EXISTS archivo_contenido BYTEA,
    ADD COLUMN IF NOT EXISTS archivo_tipo      VARCHAR(100),
    ADD COLUMN IF NOT EXISTS archivo_tamano    INTEGER;
