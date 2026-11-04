-- Agrega a "escenas" los campos que son PROPIOS del Plan de Rodaje
-- (referente FilmScript: SET, LOCACIÓN DE RODAJE, TIEMPO EST., HORA DE
-- INICIO y NOTAS por fila del stripboard) — distintos de los datos
-- narrativos de la escena (encabezado, descripción, INT/EXT, momento,
-- día dramático, etc.). Solo tienen sentido mientras la escena está
-- asignada a un día de rodaje (id_rodaje) y se editan desde la
-- pantalla de Plan de Rodaje.
--
-- No se creó una tabla aparte porque la relación escena->día de
-- rodaje ya es 1:1 (escenas.id_rodaje), así que agregar estas columnas
-- directo en "escenas" evita una tabla puente innecesaria.

ALTER TABLE escenas
    ADD COLUMN IF NOT EXISTS locacion_rodaje    TEXT,
    ADD COLUMN IF NOT EXISTS tiempo_estimado    TEXT,
    ADD COLUMN IF NOT EXISTS hora_inicio_rodaje TIME,
    ADD COLUMN IF NOT EXISTS notas_rodaje       TEXT,
    ADD COLUMN IF NOT EXISTS orden_rodaje       INTEGER;
