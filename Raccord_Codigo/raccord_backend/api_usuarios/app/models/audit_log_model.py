import uuid

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from app.config.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id_audit = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    id_user = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    action = Column(String(100), nullable=False, index=True)
    module = Column(String(50), nullable=False, index=True)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(100), nullable=True)

    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)

    success = Column(Boolean, nullable=False, index=True)
    details = Column(Text, nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    __table_args__ = (
        Index("ix_audit_logs_project_created", "id_project", "created_at"),
    )
