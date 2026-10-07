-- Agrega "bloque_grabacion" a "escenas": un número (1, 2, 3...) que el
-- equipo de producción asigna a mano para agrupar escenas en bloques de
-- grabación, independiente de a qué día de rodaje esté asignada cada
-- escena. Se usa para filtrar en Plan de Rodaje y en Escenas — pedido
-- explícito del usuario.

ALTER TABLE escenas
    ADD COLUMN IF NOT EXISTS bloque_grabacion INTEGER;
