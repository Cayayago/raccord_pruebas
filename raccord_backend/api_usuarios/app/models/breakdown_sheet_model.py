import uuid
from sqlalchemy import Column, Integer, String, Text, Time, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# BREAKDOWN SHEET MODEL (tabla "desgloses")
# ==========================================
# Es el CONTENEDOR del desglose por semana/día (no confundir con
# desglose_items / desglose_item_detalle de app/models/breakdown_model.py,
# que son el detalle por categoría de cada escena). Este contenedor
# agrupa, por semana y día de rodaje, las escenas que se desglosaron
# juntas. Las escenas se relacionan por escenas.id_desglose (FK ON
# DELETE CASCADE hacia acá).
#
# "requerimientos" es el campo libre que ya traía la tabla original en
# el dump (NOT NULL); queda como resumen/notas generales del desglose
# de ese día, en paralelo a la info estructurada de desglose_items.
#
# id_desglose NO se genera en Python: la columna en la BD tiene
# DEFAULT ('desg' || nextval(desglose_seq)), automático igual que un
# SERIAL. Se deja sin default acá para que Postgres la complete y
# SQLAlchemy la recupere con RETURNING.
class BreakdownSheet(Base):
    __tablename__ = "desgloses"

    id_desglose = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    # Aislamiento por proyecto (ver sql/015_project_scoping.sql) — mismo
    # razonamiento que ShootingDay: no se puede resolver únicamente vía
    # las escenas que apuntan acá (escenas.id_desglose) porque este
    # contenedor puede crearse antes de asignarle escenas. Nullable=True
    # solo para la migración de filas existentes; toda fila nueva lo
    # exige (BreakdownSheetSchema).
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

    requerimientos = Column(
        Text,
        nullable=False
    )

    activo = Column(
        Boolean,
        default=True
    )
