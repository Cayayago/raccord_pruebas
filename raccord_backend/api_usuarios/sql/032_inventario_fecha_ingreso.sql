-- ==========================================================
-- 032: Inventario — fecha de ingreso
-- ==========================================================
-- create_all() NO modifica tablas existentes, así que esta columna
-- hay que agregarla a mano en bases ya creadas. Los elementos
-- existentes quedan con la fecha en que se crearon.
ALTER TABLE inventario ADD COLUMN IF NOT EXISTS fecha_ingreso DATE;
UPDATE inventario SET fecha_ingreso = fecha_creacion::date WHERE fecha_ingreso IS NULL;
ALTER TABLE inventario ALTER COLUMN fecha_ingreso SET DEFAULT CURRENT_DATE;
ALTER TABLE inventario ALTER COLUMN fecha_ingreso SET NOT NULL;

-- Tipos nuevos: "Vestido" y "Traje completo" pasan a ser tipos separados.
-- Los elementos guardados como "Vestido / Traje completo" se pasan a "Vestido".
UPDATE inventario SET tipo = 'Vestido' WHERE tipo = 'Vestido / Traje completo';
