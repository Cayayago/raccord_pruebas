import uuid
from sqlalchemy import Column, String, Integer, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# CHARACTER MODEL (tabla "personajes")
# ==========================================
# id_personaje es UUID, generado en Python (uuid.uuid4) — ver
# sql/009_uuid_primary_keys.sql. Antes lo armaba un trigger
# (gen_id_personaje, 'cast1', 'cast2'...) con una secuencia central.
class Character(Base):
    __tablename__ = "personajes"

    id_personaje = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    nombre = Column(
        String(45),
        nullable=False
    )

    edad = Column(
        Integer,
        nullable=False
    )

    codigo_personaje = Column(
        String(30),
        nullable=False
    )

    # Aislamiento de datos por proyecto (ver sql/015_project_scoping.sql):
    # antes esta tabla no tenía NINGUNA relación con "projects", así que
    # GET /characters devolvía los personajes de TODOS los proyectos de
    # TODOS los clientes sin distinción. Nullable=True a nivel de BD solo
    # para permitir la migración de filas existentes (ver
    # scripts/backfill_project_scoping.py); toda fila nueva SIEMPRE debe
    # traer id_project (se exige en CharacterSchema).
    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
