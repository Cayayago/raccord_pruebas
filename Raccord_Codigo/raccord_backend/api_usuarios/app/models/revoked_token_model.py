from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from app.config.database import Base


# LISTA DE REVOCACIÓN DE JWT (LOGOUT REAL)
#
# El JWT de Raccord es stateless por diseño: create_access_token
# (app/utils/security.py) no guarda nada en la BD, solo firma un
# payload con expiración. Eso significa que un "logout" que solo
# borra el token del lado del cliente (ver antes AuthSession.logout()
# en el frontend) NO lo invalida de verdad — el mismo token seguiría
# sirviendo contra la API hasta cumplir sus 60 minutos, aunque el
# usuario ya haya cerrado sesión en pantalla.
#
# Esta tabla es la lista de revocación: cada JWT lleva un "jti" (id
# único de ESE token, no del usuario — ver create_access_token). Al
# hacer POST /users/logout, ese jti se guarda acá. get_current_user
# (app/middleware/auth.py) rechaza cualquier token cuyo jti aparezca
# en esta tabla, aunque la firma y el "exp" sigan siendo válidos.
class RevokedToken(Base):
    __tablename__ = "tokens_revocados"

    jti = Column(String(36), primary_key=True)

    # Copia del "exp" que ya traía el JWT. Sirve solo para la
    # autolimpieza (ver token_revocation._limpiar_expirados): un jti
    # vencido ya no serviría de todas formas aunque no estuviera en
    # esta tabla, así que no hace falta guardarlo para siempre.
    fecha_expira = Column(DateTime, nullable=False, index=True)

    fecha_revocado = Column(DateTime, server_default=func.now())
