-- ==========================================================
-- RNF-004: bloqueo por intentos fallidos de login
-- ==========================================================
--   5 fallos por cuenta en 15 min -> cuenta bloqueada 15 min
--   20 fallos desde una IP en 1 h -> IP bloqueada 1 h
--   10 fallos por cuenta en 24 h  -> bloqueo hasta que un administrador
--                                    llame POST /users/{id}/desbloquear
--
-- NOTA: no hace falta correr este archivo — Base.metadata.create_all()
-- crea ambas tablas al arrancar el backend (no se toca "users").
-- Se deja como documentación del esquema. Horas en UTC.
CREATE TABLE IF NOT EXISTS login_intentos (
    id BIGSERIAL PRIMARY KEY,
    mail VARCHAR(150) NOT NULL,
    ip VARCHAR(64) NOT NULL,
    fecha TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_login_intentos_mail ON login_intentos (mail);
CREATE INDEX IF NOT EXISTS idx_login_intentos_ip ON login_intentos (ip);
CREATE INDEX IF NOT EXISTS idx_login_intentos_fecha ON login_intentos (fecha);

-- clave: 'cuenta:<correo>' | 'ip:<direccion>' | 'admin:<correo>'
-- hasta NULL = no vence solo (requiere reset de administrador)
CREATE TABLE IF NOT EXISTS login_bloqueos (
    clave VARCHAR(220) PRIMARY KEY,
    hasta TIMESTAMP NULL,
    fecha TIMESTAMP NOT NULL
);
