import uuid
from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# DEPARTMENT MODEL
# ==========================================
# Tabla "departamentos" en la BD. id_departamento es UUID (ver
# sql/009_uuid_primary_keys.sql) — se genera en Python con uuid.uuid4()
# para que el ID pueda crearse sin ida y vuelta a la base de datos
# (clave para evitar colisiones si algún cliente llega a crear
# departamentos estando offline). Antes se armaba con un trigger de
# Postgres ('area01', 'area02', ...) basado en una secuencia central,
# que sí podía colisionar entre clientes desconectados.
class Department(Base):
    __tablename__ = "departamentos"

    id_departamento = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    nombre = Column(
        String(45),
        nullable=False
    )

    ubicacion = Column(
        Text,
        nullable=False
    )
