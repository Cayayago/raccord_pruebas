-- Semana 6 (hallazgo con la BD real): la versión del guion era UNIQUE en toda
-- la base de datos. script_controller.create_script ya validaba que la
-- versión fuera única DENTRO del proyecto, pero la tabla impedía que dos
-- productoras distintas tuvieran, cada una, un guion "V2": el segundo INSERT
-- fallaba con UniqueViolation y el API respondía 500.
--
-- Ahora la regla vive en la BD igual que en el código: única por proyecto.
-- Idempotente: se puede correr más de una vez.
ALTER TABLE guiones DROP CONSTRAINT IF EXISTS guiones_numero_de_version_key;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'guiones_proyecto_version_key'
    ) THEN
        ALTER TABLE guiones
            ADD CONSTRAINT guiones_proyecto_version_key UNIQUE (id_project, numero_de_version);
    END IF;
END $$;
