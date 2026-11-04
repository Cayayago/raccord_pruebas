-- ==========================================================
-- 030: Módulo Inventario
-- ==========================================================
-- NOTA: main.py ejecuta Base.metadata.create_all(), así que esta tabla
-- se crea sola al reiniciar el backend. Este script queda como
-- documentación / para ejecutarlo a mano si se prefiere.
--
-- "codigo" es el código VISIBLE (lo digita la persona o se autogenera
-- INV-0001...). La llave primaria es id_item (UUID); el código solo
-- debe ser único dentro del mismo proyecto.
CREATE TABLE IF NOT EXISTS inventario (
    id_item             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_project          UUID NOT NULL REFERENCES projects(id_project) ON DELETE CASCADE,
    codigo              VARCHAR(30) NOT NULL,
    tipo                VARCHAR(40) NOT NULL,
    color_predominante  VARCHAR(30),
    genero              VARCHAR(15),
    descripcion         TEXT,
    cantidad            INTEGER NOT NULL DEFAULT 1,
    origen              TEXT,
    destino             TEXT,
    composicion         TEXT,
    id_departamento     UUID REFERENCES departamentos(id_departamento) ON DELETE SET NULL,
    archivo_nombre      VARCHAR(255),
    archivo_key         TEXT,
    archivo_tipo        VARCHAR(100),
    archivo_tamano      INTEGER,
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT now(),
    creado_por          UUID REFERENCES users(id_user) ON DELETE SET NULL,
    CONSTRAINT uq_inventario_project_codigo UNIQUE (id_project, codigo)
);

-- Fotos del elemento: máximo 3, individuales (sin collage). Las columnas
-- archivo_* de "inventario" son LEGADO (la app migra sola esas fotos).
CREATE TABLE IF NOT EXISTS inventario_fotos (
    id_foto        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_item        UUID NOT NULL REFERENCES inventario(id_item) ON DELETE CASCADE,
    orden          INTEGER NOT NULL DEFAULT 1,
    archivo_nombre VARCHAR(255) NOT NULL,
    archivo_key    TEXT NOT NULL,
    archivo_tipo   VARCHAR(100) NOT NULL,
    archivo_tamano INTEGER NOT NULL,
    fecha_subida   TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_inventario_fotos_id_item ON inventario_fotos (id_item);

CREATE INDEX IF NOT EXISTS ix_inventario_id_project ON inventario (id_project);
CREATE INDEX IF NOT EXISTS ix_inventario_id_departamento ON inventario (id_departamento);
