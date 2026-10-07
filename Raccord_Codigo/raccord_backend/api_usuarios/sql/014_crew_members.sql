-- Crea "personal_produccion" (Crew List): directorio de TODAS las
-- personas que trabajan en el proyecto, tengan o no cuenta de acceso
-- a la plataforma (usuarios) — pedido explícito del usuario. Se
-- gestiona igual que personajes/actores: creación individual o carga
-- masiva (CSV/JSON) desde la pantalla Crew List.

CREATE TABLE IF NOT EXISTS personal_produccion (
    id_crew         UUID PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    cargo           VARCHAR(120) NOT NULL,
    id_departamento UUID REFERENCES departamentos(id_departamento) ON DELETE SET NULL,
    celular         VARCHAR(30),
    correo          VARCHAR(120),
    notas           TEXT
);
