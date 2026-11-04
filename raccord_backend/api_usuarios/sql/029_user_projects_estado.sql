-- Suspensión POR PROYECTO (no global).
-- Antes "suspender" cambiaba users.estado, que es global a la persona.
-- Ahora cada vínculo usuario-proyecto tiene su propio estado: la persona
-- sigue pudiendo entrar a la app, pero el proyecto suspendido deja de
-- aparecerle (y la API le niega todo lo de ese proyecto) hasta reactivarla.
BEGIN;

ALTER TABLE user_projects
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) NOT NULL DEFAULT 'activo';

ALTER TABLE user_projects
    DROP CONSTRAINT IF EXISTS user_projects_estado_chk;
ALTER TABLE user_projects
    ADD CONSTRAINT user_projects_estado_chk CHECK (estado IN ('activo', 'suspendido'));

-- Quien estaba suspendido a nivel global pasa a estarlo en TODOS sus
-- proyectos actuales, y se limpia la suspensión global para que pueda
-- seguir entrando a la app.
UPDATE user_projects up
SET estado = 'suspendido'
FROM users u
WHERE up.id_user = u.id_user AND u.estado = 'suspendido';

UPDATE users SET estado = 'activo' WHERE estado = 'suspendido';

COMMIT;
