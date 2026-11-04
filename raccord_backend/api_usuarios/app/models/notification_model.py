import uuid
from sqlalchemy import Column, String, Text, Integer, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# NOTIFICATION MODEL (tabla "notificaciones")
# ==========================================
# Módulo de Notificaciones (2026-09-27, pedido explícito del usuario):
# un tablón informativo de cara a todo el equipo del proyecto. Solo
# Jefe de Departamento y Director pueden publicar (ver
# "publish_notifications" en app/utils/permissions.py).
#
# Alcance ("tipo_alcance"):
#   - "general"   -> la ve TODO el equipo del proyecto.
#   - "especifica" -> la ve solo la gente de uno o más departamentos
#     puntuales (ver NotificationDepartamento más abajo). Tanto Jefe de
#     Departamento como Director pueden elegir VARIOS departamentos a
#     la vez (pedido explícito: un Jefe puede tener a cargo más de un
#     equipo con nombres distintos, no se lo limita a "su" departamento).
#
# Origen ("origen"):
#   - "manual"      -> la escribió alguien a mano desde la pantalla de
#     Notificaciones.
#   - "plan_rodaje" -> se generó sola a partir de cambios hechos en
#     Plan de Rodaje (ver diálogo "Notificar estos cambios al equipo" y
#     el envío automático al cerrar sesión por inactividad).
class Notification(Base):
    __tablename__ = "notificaciones"

    id_notificacion = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    id_user_autor = Column(  # quién la publicó (Jefe de Departamento o Director)
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="SET NULL"),
        nullable=True,
    )

    tipo_alcance = Column(String(20), nullable=False, server_default="general")  # "general" | "especifica"

    origen = Column(String(20), nullable=False, server_default="manual")  # "manual" | "plan_rodaje"

    texto = Column(Text, nullable=False)

    # Foto opcional (bucket "imagenes" de MinIO, mismo bucket que las
    # fotos de continuidad — ver app/utils/minio_client.py). null si la
    # notificación no trae foto.
    foto_key = Column(Text, nullable=True)
    foto_nombre = Column(String(255), nullable=True)
    foto_tipo = Column(String(100), nullable=True)
    foto_tamano = Column(Integer, nullable=True)

    fecha_creacion = Column(
        DateTime,
        nullable=False,
        server_default=func.now()
    )


# ==========================================
# NOTIFICATION DEPARTAMENTO (many-to-many: una "especifica" puede
# apuntar a varios departamentos a la vez)
# ==========================================
class NotificationDepartamento(Base):
    __tablename__ = "notificacion_departamentos"

    id_notificacion = Column(
        UUID(as_uuid=True),
        ForeignKey("notificaciones.id_notificacion", ondelete="CASCADE"),
        primary_key=True,
    )

    id_departamento = Column(
        UUID(as_uuid=True),
        ForeignKey("departamentos.id_departamento", ondelete="CASCADE"),
        primary_key=True,
    )


# ==========================================
# NOTIFICATION LEIDA (estado de lectura POR USUARIO — para el contador
# de no leídas en la campana)
# ==========================================
class NotificationRead(Base):
    __tablename__ = "notificacion_leidas"

    id_notificacion = Column(
        UUID(as_uuid=True),
        ForeignKey("notificaciones.id_notificacion", ondelete="CASCADE"),
        primary_key=True,
    )

    id_user = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="CASCADE"),
        primary_key=True,
    )

    fecha_lectura = Column(
        DateTime,
        nullable=False,
        server_default=func.now()
    )
