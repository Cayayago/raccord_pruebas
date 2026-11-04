-- ==========================================
-- MODULO: DESGLOSE DE PRODUCCION (2 niveles)
-- ==========================================
-- Estas 2 tablas son NUEVAS, no estaban en el dump original. No
-- reemplazan a "desgloses" (que sigue siendo el contenedor por
-- semana/dia que ya tienes, referenciado por escenas.id_desglose).
--
-- desglose_items       -> nivel GENERAL, por escena. Ej: escena esc014,
--                         categoria "Extras", "Gente de mercado", 95.
--                         Lo carga Administrador/Director.
-- desglose_item_detalle -> nivel ESPECIFICO, segmentacion que hace cada
--                         area sobre un item general. Ej: de esos 95,
--                         30 mujeres, 40 hombres, 25 niños. Lo edita el
--                         Jefe de Departamento dueño del item; su
--                         equipo (Onset/Usuario del mismo depto) solo
--                         lo consulta. Administrador/Director NO ven
--                         este nivel.
--
-- Corre este script contra tu Postgres real antes de probar los
-- endpoints /breakdown/*.

CREATE TABLE IF NOT EXISTS desglose_items (
    id_desglose_item   SERIAL PRIMARY KEY,
    id_escena          TEXT NOT NULL REFERENCES escenas(id_escena) ON DELETE CASCADE,
    id_departamento    TEXT REFERENCES departamentos(id_departamento),
    categoria          VARCHAR(50) NOT NULL,
    nombre_item        TEXT NOT NULL,
    cantidad           INTEGER,
    notas              TEXT,
    id_user_creador    INTEGER REFERENCES users(id_user),
    created_at         TIMESTAMP NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_desglose_items_escena ON desglose_items(id_escena);
CREATE INDEX IF NOT EXISTS idx_desglose_items_departamento ON desglose_items(id_departamento);

CREATE TABLE IF NOT EXISTS desglose_item_detalle (
    id_detalle         SERIAL PRIMARY KEY,
    id_desglose_item   INTEGER NOT NULL REFERENCES desglose_items(id_desglose_item) ON DELETE CASCADE,
    etiqueta           VARCHAR(100) NOT NULL,
    cantidad           INTEGER,
    estado             VARCHAR(20) NOT NULL DEFAULT 'pendiente'
                        CHECK (estado IN ('pendiente', 'en_progreso', 'completado')),
    prioridad          VARCHAR(10)
                        CHECK (prioridad IN ('alta', 'media', 'baja') OR prioridad IS NULL),
    notas              TEXT,
    id_user_editor     INTEGER REFERENCES users(id_user),
    updated_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_desglose_detalle_item ON desglose_item_detalle(id_desglose_item);
CREATE INDEX IF NOT EXISTS idx_desglose_detalle_estado ON desglose_item_detalle(estado);
