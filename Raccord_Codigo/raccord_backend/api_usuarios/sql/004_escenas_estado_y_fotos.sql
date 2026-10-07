-- Agrega el seguimiento de estado a las escenas (Pendiente / En
-- proceso / Finalizada — mockup de Escenas) y crea la tabla de fotos
-- de continuidad visual asociadas a cada escena (mockup "Continuidad
-- Visual").

ALTER TABLE escenas
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente';

CREATE TABLE IF NOT EXISTS fotos_continuidad (
    id_foto            SERIAL PRIMARY KEY,
    id_escena          TEXT NOT NULL REFERENCES escenas(id_escena) ON DELETE CASCADE,
    tipo_foto          VARCHAR(30) NOT NULL DEFAULT 'Set',
    personaje_codigo   VARCHAR(30),
    descripcion        TEXT,
    notas_continuidad  TEXT,
    archivo_nombre     VARCHAR(255) NOT NULL,
    archivo_contenido  BYTEA NOT NULL,
    archivo_tipo       VARCHAR(100) NOT NULL,
    archivo_tamano     INTEGER NOT NULL,
    fecha_subida       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fotos_continuidad_id_escena ON fotos_continuidad (id_escena);
