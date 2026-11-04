-- ==========================================================
-- CORREGIR REGLAS ON DELETE INCONSISTENTES/RIESGOSAS
-- ==========================================================
-- Auditoría de las 27 FK del esquema: se encontraron 3 reglas ON
-- DELETE que no coinciden con el resto del sistema y podían causar
-- comportamiento inesperado o un error genérico 500 al borrar algo.
-- Todas se corrigen a SET NULL, sin tocar ninguna tabla nueva ni
-- ningún endpoint — el borrado en cascada real (proyecto, escena,
-- personaje, etc.) sigue exactamente igual.

-- 1) users.id_departamento estaba en ON DELETE CASCADE: borrar un
--    departamento se llevaba puestas a TODAS las personas de esa
--    área. La app ya bloquea este caso a propósito
--    (department_controller.delete_department revisa que no haya
--    usuarios antes de dejar borrar), así que el CASCADE de la base de
--    datos nunca debería dispararse en uso normal — pero es una
--    trampa real si alguna vez se borra un departamento directo en
--    Adminer/SQL sin pasar por la API. Debe ser SET NULL, igual que
--    personal_produccion.id_departamento (mismo tipo de relación).
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_departamento_fkey;
ALTER TABLE users
    ADD CONSTRAINT users_id_departamento_fkey
    FOREIGN KEY (id_departamento) REFERENCES departamentos(id_departamento) ON DELETE SET NULL;

-- 2) desglose_items.id_departamento no tenía ON DELETE (por defecto,
--    Postgres BLOQUEA el borrado del departamento si tiene algún item
--    asignado) — inconsistente con personal_produccion.id_departamento,
--    que sí es SET NULL. El comentario del propio modelo
--    (DesgloseItem.id_departamento) ya dice "puede ser nulo para items
--    sin área dueña", así que perder la asignación al borrar el
--    departamento es el comportamiento esperado, no bloquear el borrado.
ALTER TABLE desglose_items DROP CONSTRAINT IF EXISTS desglose_items_id_departamento_fkey;
ALTER TABLE desglose_items
    ADD CONSTRAINT desglose_items_id_departamento_fkey
    FOREIGN KEY (id_departamento) REFERENCES departamentos(id_departamento) ON DELETE SET NULL;

-- 3) y 4) desglose_items.id_user_creador y
--    desglose_item_detalle.id_user_editor tampoco tenían ON DELETE:
--    intentar eliminar (DELETE /users/{id}) a cualquier persona que
--    alguna vez haya creado o editado un item de desglose fallaba con
--    un error de integridad referencial sin manejar — el
--    controller (user_controller.delete_user) no captura esa
--    excepción, así que el usuario final veía el 500 genérico
--    ("Ocurrió un error inesperado en el servidor") en vez de un
--    mensaje claro. Son columnas de auditoría (quién lo creó/editó),
--    no de dueño del dato: perder esa referencia al borrar la cuenta
--    es aceptable, igual que ya se hizo con
--    user_project_module_access.id_actualizado_por.
ALTER TABLE desglose_items DROP CONSTRAINT IF EXISTS desglose_items_id_user_creador_fkey;
ALTER TABLE desglose_items
    ADD CONSTRAINT desglose_items_id_user_creador_fkey
    FOREIGN KEY (id_user_creador) REFERENCES users(id_user) ON DELETE SET NULL;

ALTER TABLE desglose_item_detalle DROP CONSTRAINT IF EXISTS desglose_item_detalle_id_user_editor_fkey;
ALTER TABLE desglose_item_detalle
    ADD CONSTRAINT desglose_item_detalle_id_user_editor_fkey
    FOREIGN KEY (id_user_editor) REFERENCES users(id_user) ON DELETE SET NULL;
