-- RNF-027: estado temporal compartido entre instancias del backend.
-- Lo crea solo Base.metadata.create_all al arrancar; este archivo documenta
-- la tabla y sirve para crearla a mano si se prefiere.
CREATE TABLE IF NOT EXISTS estado_temporal (
    clave        VARCHAR(400) PRIMARY KEY,
    valor        TEXT         NOT NULL,
    fecha_expira TIMESTAMP    NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_estado_temporal_fecha_expira ON estado_temporal (fecha_expira);
