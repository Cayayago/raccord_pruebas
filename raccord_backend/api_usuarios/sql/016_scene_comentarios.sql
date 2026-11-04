-- Agrega "comentarios" a "escenas": campo de texto libre editable desde
-- el panel "Información de la Escena" en Continuidad Visual, distinto
-- de "descripcion" (sinopsis narrativa fijada al crear la escena) y de
-- "notas_rodaje" (específicas del día de rodaje) — pedido explícito del
-- usuario (2026-09-02).

ALTER TABLE escenas
    ADD COLUMN IF NOT EXISTS comentarios TEXT;
