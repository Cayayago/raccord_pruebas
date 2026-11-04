-- ==========================================
-- 011_users_id_client.sql
-- ==========================================
-- Bug real (no relacionado con la migración a UUID en sí): un usuario
-- recién registrado (POST /register) no queda vinculado a NINGÚN
-- proyecto todavía, así que el único mecanismo que existía para saber
-- su id_client -- login_controller._get_client_from_user, que busca a
-- través de user_projects -> projects.id_client -- no encuentra nada.
-- Resultado: session.user.idClient llega vacío al frontend, y la
-- pantalla obligatoria "Registra Proyecto" (el primer proyecto de la
-- cuenta) manda un id_client vacío -> error 500 al crear el proyecto.
--
-- Fix: guardar el id_client directamente en users, seteado en el
-- momento en que se crea el usuario (tanto en /register como en
-- /users/invite, que ya recibe id_client como parámetro). Así
-- login_controller ya no necesita adivinarlo por un join indirecto.

BEGIN;

ALTER TABLE users
    ADD COLUMN id_client uuid REFERENCES clients(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE;

-- Backfill para las cuentas de prueba que ya se registraron antes de
-- este fix (van a tener id_client NULL porque la columna no existía
-- cuando se crearon). Dos casos cubiertos, del más al menos preciso:
--   1) el correo de empresa coincide con el correo personal del
--      usuario (pasa en las pruebas manuales, ej. registro con el
--      mismo correo en ambos campos).
--   2) solo hay UN cliente y UN usuario sin id_client todavía -> son
--      pareja, se vinculan.
-- Si tienes varias cuentas de prueba con correos distintos, borra los
-- datos de prueba y vuelve a registrarte (ya queda bien desde ahora).
UPDATE users u
SET id_client = c.id_cliente
FROM clients c
WHERE u.id_client IS NULL AND u.mail = c.email;

UPDATE users u
SET id_client = (SELECT id_cliente FROM clients LIMIT 1)
WHERE u.id_client IS NULL
  AND (SELECT COUNT(*) FROM clients) = 1
  AND (SELECT COUNT(*) FROM users WHERE id_client IS NULL) = 1;

COMMIT;
