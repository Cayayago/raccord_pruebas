-- Agrega las dos fotos del actor a "actors": "foto_personaje_key"
-- (caracterizado, en personaje) y "foto_normal_key" (su propia imagen)
-- — pedido explícito del usuario (2026-09-02), primer paso de la
-- ficha técnica del actor. Mismo patrón que users.foto_perfil_key:
-- solo se guarda la key del objeto en MinIO (bucket "imagenes"), nunca
-- el binario en Postgres.

ALTER TABLE actors
    ADD COLUMN IF NOT EXISTS foto_personaje_key TEXT,
    ADD COLUMN IF NOT EXISTS foto_normal_key TEXT;
