-- Estado del proyecto (pantalla "Gestión de Proyectos").
--
--   estado             : preliminar | en_rodaje | suspendido | finalizado
--   causal_suspension  : temporal | indefinido | incumplimiento
--                        (solo cuando estado = 'suspendido')
--
-- Los proyectos que ya existen quedan en 'preliminar'. Las restricciones
-- CHECK garantizan en la propia BD que la causal solo exista (y sea
-- obligatoria) cuando el proyecto está suspendido.

ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'preliminar';

ALTER TABLE projects
    ADD COLUMN IF NOT EXISTS causal_suspension VARCHAR(20);

ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_estado_chk;
ALTER TABLE projects
    ADD CONSTRAINT projects_estado_chk
    CHECK (estado IN ('preliminar', 'en_rodaje', 'suspendido', 'finalizado'));

ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_causal_chk;
ALTER TABLE projects
    ADD CONSTRAINT projects_causal_chk
    CHECK (causal_suspension IS NULL
           OR causal_suspension IN ('temporal', 'indefinido', 'incumplimiento'));

-- Causal obligatoria si está suspendido; prohibida en cualquier otro estado.
ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_causal_vs_estado_chk;
ALTER TABLE projects
    ADD CONSTRAINT projects_causal_vs_estado_chk
    CHECK ((estado = 'suspendido' AND causal_suspension IS NOT NULL)
        OR (estado <> 'suspendido' AND causal_suspension IS NULL));
