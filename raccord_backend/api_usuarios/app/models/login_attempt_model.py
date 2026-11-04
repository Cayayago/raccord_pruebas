from datetime import datetime

from sqlalchemy import BigInteger, Column, DateTime, Integer, String
from app.config.database import Base


# RNF-004 — PROTECCIÓN CONTRA FUERZA BRUTA EN EL LOGIN
#
# Dos tablas nuevas (las crea Base.metadata.create_all al arrancar el
# backend, no hace falta migración manual ni se toca la tabla users):
#
#  - login_intentos: un renglón por cada intento FALLIDO (correo, IP,
#    momento). De aquí se cuentan los fallos por ventana de tiempo.
#  - login_bloqueos: bloqueos ya decididos. "clave" es
#    "cuenta:<correo>", "ip:<direccion>" o "admin:<correo>".
#    "hasta" = hasta cuándo dura; NULL = no vence solo (bloqueo de
#    cuenta que exige reset por un administrador).
#
# Se guardan en la BD (y no en memoria como rate_limit.py) para que los
# bloqueos sobrevivan a reinicios del backend y funcionen con varios
# procesos. Las horas se guardan en UTC.
class LoginAttempt(Base):
    __tablename__ = "login_intentos"

    # BIGSERIAL en Postgres; la variante Integer solo existe para poder
    # probar la lógica con SQLite en memoria (que no autoincrementa BIGINT).
    id = Column(BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True)
    # Se guarda el correo tal cual lo escribieron (normalizado) aunque
    # NO exista como usuario: así "correo inexistente" y "contraseña
    # incorrecta" se comportan exactamente igual (no se puede usar el
    # login para averiguar qué correos están registrados).
    mail = Column(String(150), nullable=False, index=True)
    ip = Column(String(64), nullable=False, index=True)
    fecha = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)


class LoginBlock(Base):
    __tablename__ = "login_bloqueos"

    clave = Column(String(220), primary_key=True)
    hasta = Column(DateTime, nullable=True)
    fecha = Column(DateTime, nullable=False, default=datetime.utcnow)
