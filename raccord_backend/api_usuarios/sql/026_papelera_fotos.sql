-- ==========================================================
-- PAPELERA DE RECICLAJE: fotos de continuidad (fotos_continuidad)
-- ==========================================================
-- Antes, eliminar una foto la borraba para siempre de una vez (DELETE
-- físico + borrado del binario en MinIO). Ahora "eliminar" es un
-- soft-delete: la foto se marca como eliminada y se oculta de los
-- listados normales (Galería/Continuidad), pero sigue existiendo
-- hasta que alguien la elimine DEFINITIVAMENTE desde la Papelera.
--
-- Permisos (ver app/utils/permissions.py):
--   - "delete_photos" (mover a la papelera): Onset, Jefe de
--     Departamento, Director. El Administrador YA NO puede eliminar
--     fotos (solo verlas).
--   - "manage_recycle_bin" (restaurar o eliminar definitivo): SOLO
--     Jefe de Departamento y Director.
--   - "view_recycle_bin" (ver la pantalla de Papelera): Jefe de
--     Departamento, Director y Administrador (este último de solo
--     lectura, sin botones de acción).
--
-- NOTA: esta tabla YA EXISTE (creada en 000_schema_completo.sql /
-- 004_escenas_estado_y_fotos.sql), por eso hace falta ALTER TABLE acá
-- a mano — a diferencia de una tabla nueva, que Base.metadata.
-- create_all() crea sola al arrancar el backend.
ALTER TABLE fotos_continuidad
    ADD COLUMN IF NOT EXISTS eliminada BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE fotos_continuidad
    ADD COLUMN IF NOT EXISTS fecha_eliminacion TIMESTAMP NULL;

ALTER TABLE fotos_continuidad
    ADD COLUMN IF NOT EXISTS eliminada_por UUID NULL
        REFERENCES users(id_user) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_fotos_continuidad_eliminada
    ON fotos_continuidad (eliminada);
