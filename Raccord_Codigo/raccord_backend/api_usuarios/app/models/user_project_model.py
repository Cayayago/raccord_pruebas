import uuid
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.config.database import Base

# id_rol se deja como entero a propósito (igual que en User): el
# sistema de permisos usa los IDs fijos 1001-1005 de "roles", que no
# se convirtió a UUID.
class UserProject(Base):
    __tablename__ = "user_projects"
    # Esta tabla resuelve el ROL EFECTIVO de cada persona en cada
    # proyecto (ver app/utils/project_scope.py::get_role_in_project) —
    # se consulta en prácticamente TODA petición autenticada de la API.
    # Sin este índice compuesto no tenía NINGÚN índice más allá de su PK
    # "id", que no sirve para este filtro (ver
    # sql/022_indices_faltantes.sql).
    __table_args__ = (
        Index("idx_user_projects_user_project", "id_user", "id_project"),
    )

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    id_user = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="CASCADE"),
        nullable=False
    )

    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    id_rol = Column(
        Integer,
        nullable=False,
        default=1005
    )

    fecha_vinculacion = Column(
        DateTime,
        server_default=func.now()
    )