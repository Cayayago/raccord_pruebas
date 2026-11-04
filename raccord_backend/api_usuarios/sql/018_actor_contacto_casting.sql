-- Agrega a "actors" los campos de contacto de producción y de
-- seguimiento de casting que trae un Cast List real (cédula,
-- dirección, teléfono, correo, status de confirmación, llamados,
-- fechas tentativas, guion enviado, ensayos, categoría de cast) —
-- pedido explícito del usuario (2026-09-02), tras comparar la ficha
-- técnica contra el Cast List de un proyecto.

ALTER TABLE actors
    ADD COLUMN IF NOT EXISTS cedula VARCHAR(50),
    ADD COLUMN IF NOT EXISTS direccion TEXT,
    ADD COLUMN IF NOT EXISTS telefono VARCHAR(30),
    ADD COLUMN IF NOT EXISTS correo VARCHAR(120),
    ADD COLUMN IF NOT EXISTS status_confirmacion VARCHAR(20),
    ADD COLUMN IF NOT EXISTS llamados TEXT,
    ADD COLUMN IF NOT EXISTS fechas_tentativas TEXT,
    ADD COLUMN IF NOT EXISTS guion_enviado BOOLEAN,
    ADD COLUMN IF NOT EXISTS ensayos TEXT,
    ADD COLUMN IF NOT EXISTS categoria_cast VARCHAR(30);
