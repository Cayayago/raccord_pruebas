-- ==========================================================
-- 033: Auditoría y trazabilidad (RF-009)
-- ==========================================================
-- main.py ejecuta Base.metadata.create_all(), así que la tabla se crea
-- sola al reiniciar el backend. Este script queda como documentación
-- / para ejecutarlo a mano.
CREATE TABLE IF NOT EXISTS audit_logs (
    id_audit    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user     UUID REFERENCES users(id_user) ON DELETE SET NULL,
    id_project  UUID REFERENCES projects(id_project) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    module      VARCHAR(50)  NOT NULL,
    entity_type VARCHAR(50),
    entity_id   VARCHAR(100),
    ip_address  VARCHAR(45),
    user_agent  TEXT,
    success     BOOLEAN NOT NULL,
    details     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_audit_logs_id_user    ON audit_logs (id_user);
CREATE INDEX IF NOT EXISTS ix_audit_logs_id_project ON audit_logs (id_project);
CREATE INDEX IF NOT EXISTS ix_audit_logs_action     ON audit_logs (action);
CREATE INDEX IF NOT EXISTS ix_audit_logs_module     ON audit_logs (module);
CREATE INDEX IF NOT EXISTS ix_audit_logs_success    ON audit_logs (success);
CREATE INDEX IF NOT EXISTS ix_audit_logs_created_at ON audit_logs (created_at);
CREATE INDEX IF NOT EXISTS ix_audit_logs_project_created ON audit_logs (id_project, created_at);
