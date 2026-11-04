import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.config.database import Base


# ==========================================
# EXCEPCIÓN DE ACCESO POR MÓDULO (capa liviana sobre el rol)
# ==========================================
# Una fila = "esta persona, en este proyecto, en este módulo, queda
# forzada a este nivel" — ver contexto completo en
# sql/021_module_access_overrides.sql y app/utils/module_access.py.
# NO reemplaza a user_projects.id_rol (el rol sigue siendo la base);
# esto es solo la excepción puntual, y solo puede restringir, nunca
# ampliar, lo que el rol ya permitiría.
class UserProjectModuleAccess(Base):
    __tablename__ = "user_project_module_access"
    __table_args__ = (
        UniqueConstraint("id_user", "id_project", "modulo", name="uq_module_access_persona_modulo"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    id_user = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="CASCADE"),
        nullable=False,
    )

    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=False,
    )

    # Una de las claves de MODULOS (app/utils/module_access.py) — no se
    # declara como FK/Enum a propósito, mismo criterio que
    # CrewMember.cargo: es más simple mantenerlo en código Python que
    # agregar una tabla catálogo para 9 valores fijos.
    modulo = Column(String(30), nullable=False)

    # Una de las claves de NIVELES (sin_acceso, ver, comentar, editar,
    # administrar) — ver app/utils/module_access.py.
    nivel = Column(String(20), nullable=False)

    id_actualizado_por = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="SET NULL"),
        nullable=True,
    )

    fecha_actualizacion = Column(DateTime, server_default=func.now(), onupdate=func.now())
