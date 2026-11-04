-- ==========================================================
-- MÓDULO DE NOTIFICACIONES (2026-09-27)
-- ==========================================================
-- Tablón informativo de cara a todo el equipo del proyecto. Solo Jefe
-- de Departamento y Director pueden publicar (ver "publish_notifications"
-- en app/utils/permissions.py). Una notificación es "general" (todo el
-- proyecto) o "especifica" (uno o más departamentos puntuales — tanto
-- Jefe de Departamento como Director pueden elegir varios a la vez).
--
-- NOTA: estas 3 tablas son NUEVAS, así que en teoría
-- Base.metadata.create_all() (app/main.py) las crea solas al arrancar
-- el backend — este archivo queda solo como documentación histórica
-- del esquema, igual que el resto de sql/ (ver 025_tokens_revocados.sql).
CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion UUID PRIMARY KEY,
    id_project UUID NOT NULL REFERENCES projects(id_project) ON DELETE CASCADE,
    id_user_autor UUID NULL REFERENCES users(id_user) ON DELETE SET NULL,
    tipo_alcance VARCHAR(20) NOT NULL DEFAULT 'general',
    origen VARCHAR(20) NOT NULL DEFAULT 'manual',
    texto TEXT NOT NULL,
    foto_key TEXT NULL,
    foto_nombre VARCHAR(255) NULL,
    foto_tipo VARCHAR(100) NULL,
    foto_tamano INTEGER NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notificaciones_project
    ON notificaciones (id_project);

CREATE TABLE IF NOT EXISTS notificacion_departamentos (
    id_notificacion UUID NOT NULL REFERENCES notificaciones(id_notificacion) ON DELETE CASCADE,
    id_departamento UUID NOT NULL REFERENCES departamentos(id_departamento) ON DELETE CASCADE,
    PRIMARY KEY (id_notificacion, id_departamento)
);

CREATE TABLE IF NOT EXISTS notificacion_leidas (
    id_notificacion UUID NOT NULL REFERENCES notificaciones(id_notificacion) ON DELETE CASCADE,
    id_user UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    fecha_lectura TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (id_notificacion, id_user)
);
