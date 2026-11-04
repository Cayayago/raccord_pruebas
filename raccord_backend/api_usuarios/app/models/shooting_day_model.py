import uuid
from sqlalchemy import Column, Integer, String, Text, Time, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# SHOOTING DAY MODEL (tabla "plan_rodaje")
# ==========================================
# Representa un día de rodaje dentro del cronograma (el "stripboard"):
# semana, número de día de rodaje, horario de call time, locación y
# notas generales de ese día. Las escenas que se filman ese día se
# relacionan por escenas.id_rodaje (FK ON DELETE CASCADE hacia acá).
#
# id_rodaje NO se genera en Python: en la BD la columna tiene
# DEFAULT ('rod' || nextval(plan_rodaje_seq)), igual de automático que
# un SERIAL. Se deja sin default en el modelo para que Postgres la
# complete y SQLAlchemy la recupere con RETURNING (mismo patrón que
# Department/Scene, aunque allá el mecanismo es un trigger).
class ShootingDay(Base):
    __tablename__ = "plan_rodaje"

    id_rodaje = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    # Aislamiento por proyecto (ver sql/015_project_scoping.sql). No se
    # puede resolver "hacia atrás" vía las escenas que apuntan a este día
    # (escenas.id_rodaje) porque un día de rodaje puede crearse ANTES de
    # asignarle ninguna escena — necesitaría su propio id_project desde
    # el momento de creación. Nullable=True solo para la migración de
    # filas existentes; toda fila nueva lo exige (ShootingDaySchema).
    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    version = Column(
        String(50),
        nullable=False
    )

    semana_grabacion = Column(
        Integer,
        nullable=True
    )

    dia_rodaje = Column(
        Integer,
        nullable=True
    )

    hora_inicio = Column(
        Time,
        nullable=True
    )

    hora_fin = Column(
        Time,
        nullable=True
    )

    location = Column(
        String(200),
        nullable=True
    )

    notas = Column(
        Text,
        nullable=True
    )

    activo = Column(
        Boolean,
        default=True
    )
