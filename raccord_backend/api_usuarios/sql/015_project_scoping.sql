-- ==========================================================
-- AISLAMIENTO DE DATOS POR PROYECTO (multi-tenant real)
-- ==========================================================
-- Hallazgo: personajes, actors, personal_produccion, plan_rodaje y
-- desgloses nunca tuvieron ninguna relación con "projects". Cualquier
-- usuario autenticado en CUALQUIER proyecto (de cualquier cliente)
-- podía ver/editar/borrar los personajes, actores, crew, días de
-- rodaje y hojas de desglose de TODOS los demás proyectos, porque los
-- endpoints "listar todo" no tenían ningún WHERE que los separara.
--
-- Esta migración agrega la columna id_project a esas 5 tablas.
-- Nullable a propósito: las filas existentes no tienen forma de saber
-- su proyecto todavía (nunca se guardó esa información). El script
-- scripts/backfill_project_scoping.py debe correr DESPUÉS de este SQL
-- para completar lo que se pueda inferir vía relaciones existentes
-- (personajes usados en escenas, actores con personaje ya inferido,
-- etc.) y reportar qué filas quedaron "huérfanas" (sin proyecto
-- determinable) para que un administrador las asigne manualmente o
-- las elimine si son datos de prueba.
--
-- Después del backfill, es responsabilidad de la aplicación (ya no de
-- esta migración) exigir id_project en cada fila NUEVA: los schemas de
-- creación (CharacterSchema, ActorSchema, CrewMemberSchema,
-- ShootingDaySchema, BreakdownSheetSchema) ya lo declaran como
-- obligatorio.

ALTER TABLE personajes
    ADD COLUMN IF NOT EXISTS id_project UUID REFERENCES projects(id_project) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_personajes_id_project ON personajes(id_project);

ALTER TABLE actors
    ADD COLUMN IF NOT EXISTS id_project UUID REFERENCES projects(id_project) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_actors_id_project ON actors(id_project);

ALTER TABLE personal_produccion
    ADD COLUMN IF NOT EXISTS id_project UUID REFERENCES projects(id_project) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_personal_produccion_id_project ON personal_produccion(id_project);

ALTER TABLE plan_rodaje
    ADD COLUMN IF NOT EXISTS id_project UUID REFERENCES projects(id_project) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_plan_rodaje_id_project ON plan_rodaje(id_project);

ALTER TABLE desgloses
    ADD COLUMN IF NOT EXISTS id_project UUID REFERENCES projects(id_project) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_desgloses_id_project ON desgloses(id_project);
