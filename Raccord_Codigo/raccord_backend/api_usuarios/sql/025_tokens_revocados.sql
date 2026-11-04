-- ==========================================================
-- LOGOUT REAL: invalidar el JWT en el servidor al cerrar sesión
-- ==========================================================
-- Antes, "Salir" solo borraba el token del lado del cliente
-- (SharedPreferences, ver AuthSession.logout() en el frontend) — el
-- JWT seguía siendo válido en el backend hasta su expiración natural
-- (60 min por defecto, ACCESS_TOKEN_EXPIRE_MINUTES), aunque el
-- usuario ya hubiera cerrado sesión en pantalla.
--
-- Esta tabla es la lista de revocación: cada JWT lleva un "jti" (id
-- único de ESE token, ver create_access_token en
-- app/utils/security.py). Al hacer POST /users/logout, ese jti se
-- guarda acá. get_current_user (app/middleware/auth.py) rechaza
-- cualquier token cuyo jti esté en esta tabla, aunque la firma y el
-- "exp" sigan siendo válidos.
--
-- fecha_expira = la misma "exp" que ya traía el JWT: sirve para
-- autolimpiar filas viejas (ver token_revocation._limpiar_expirados)
-- — un jti vencido ya no serviría de todas formas, así que no hace
-- falta guardarlo para siempre.
--
-- NOTA: no hace falta correr este archivo a mano — Base.metadata.
-- create_all() (app/main.py) crea esta tabla sola la próxima vez que
-- arranque el backend, igual que con cualquier modelo nuevo en este
-- proyecto. Se deja el DDL acá solo por consistencia con el resto de
-- sql/ (documentación histórica del esquema).
CREATE TABLE IF NOT EXISTS tokens_revocados (
    jti VARCHAR(36) PRIMARY KEY,
    fecha_expira TIMESTAMP NOT NULL,
    fecha_revocado TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tokens_revocados_fecha_expira
    ON tokens_revocados (fecha_expira);
