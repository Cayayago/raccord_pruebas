import uuid
from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# id_project es UUID (antes texto "projNNNN" generado por una función
# de Postgres con secuencia central) — ver sql/009_uuid_primary_keys.sql.
class Project(Base):
    __tablename__ = "projects"

    id_project = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    project_name = Column(
        String(45),
        nullable=False
    )

    formato_de_produccion = Column(
        String(50),
        nullable=False
    )

    genero = Column(
        String(50),
        nullable=False
    )

    sinopsis = Column(
        Text
    )

    director = Column(
        String(255)
    )

    # Estado del proyecto — ver sql/028_proyecto_estado.sql.
    # preliminar | en_rodaje | suspendido | finalizado
    estado = Column(
        String(20),
        nullable=False,
        default="preliminar",
        server_default="preliminar",
    )

    # Solo cuando estado == "suspendido": temporal | indefinido | incumplimiento
    causal_suspension = Column(
        String(20),
        nullable=True,
    )

    # index=True: aislamiento multi-tenant, se filtra por cliente en
    # cada listado de proyectos de una empresa (ver
    # sql/022_indices_faltantes.sql).
    id_client = Column(  # llave foránea -> clients.id_cliente
        UUID(as_uuid=True),
        ForeignKey("clients.id_cliente", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )