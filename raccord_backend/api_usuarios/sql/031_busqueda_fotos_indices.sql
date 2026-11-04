-- ==========================================================
-- RNF-008 / RNF-009: índices para búsqueda de fotos con 10.000+ registros
-- ==========================================================
-- Aplicar (idempotente, se puede repetir):
--   docker compose cp raccord_backend/api_usuarios/sql/031_busqueda_fotos_indices.sql db:/tmp/031.sql
--   docker compose exec db psql -U carlos.yaya -d raccord -f /tmp/031.sql
--
-- La búsqueda (GET /fotos/project/{id}/buscar) une fotos -> escenas ->
-- guiones y filtra por proyecto, estado de papelera, tipo, personaje,
-- fecha y texto. Estos índices cubren esos filtros.

-- Orden por defecto del listado (más recientes primero) sin papelera.
CREATE INDEX IF NOT EXISTS idx_fotos_activas_fecha
    ON fotos_continuidad (fecha_subida DESC)
    WHERE eliminada = false;

-- Fotos de una escena, ya filtradas por papelera y ordenadas.
CREATE INDEX IF NOT EXISTS idx_fotos_escena_activas
    ON fotos_continuidad (id_escena, fecha_subida DESC)
    WHERE eliminada = false;

CREATE INDEX IF NOT EXISTS idx_fotos_tipo_foto ON fotos_continuidad (tipo_foto);
CREATE INDEX IF NOT EXISTS idx_fotos_personaje ON fotos_continuidad (personaje_codigo);

-- Día dramático (filtro de la Galería).
CREATE INDEX IF NOT EXISTS idx_escenas_dia_dramatico ON escenas (dia_dramatico);

-- Búsqueda de texto con ILIKE '%...%': sin esto Postgres recorre toda la
-- tabla. pg_trgm permite usar índice para texto parcial. Requiere
-- permiso para crear extensiones (el usuario del compose lo tiene).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_fotos_descripcion_trgm
    ON fotos_continuidad USING gin (descripcion gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fotos_nombre_trgm
    ON fotos_continuidad USING gin (archivo_nombre gin_trgm_ops);

ANALYZE fotos_continuidad;
ANALYZE escenas;
