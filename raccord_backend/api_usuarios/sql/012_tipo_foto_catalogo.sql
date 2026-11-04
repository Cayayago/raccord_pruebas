-- ==========================================
-- 012_tipo_foto_catalogo.sql
-- ==========================================
-- Catálogo de tipo_foto (fotos de continuidad) cambia de
-- [Propuesta, Prueba, Set] a [Locación, Propuesta, Prueba, En Rodaje]
-- -- "Set" queda reemplazado por "En Rodaje". Actualiza filas
-- existentes con ese valor y el DEFAULT de la columna.

BEGIN;

UPDATE fotos_continuidad SET tipo_foto = 'En Rodaje' WHERE tipo_foto = 'Set';
ALTER TABLE fotos_continuidad ALTER COLUMN tipo_foto SET DEFAULT 'Propuesta';

COMMIT;
