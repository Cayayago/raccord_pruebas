import uuid
from sqlalchemy import Column, Integer, String, Text, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# SCRIPT MODEL (tabla "guiones")
# ==========================================
# "estado" es un ENUM en Postgres (estado_guion: Borrador, Revisión,
# Aprobado, En Rodaje, Archivado). Igual que "document" en Client o
# "formato_de_produccion"/"genero" en Project, se mapea como texto
# plano en el modelo — psycopg2 convierte el enum de Postgres a string
# de forma transparente, y así se evita depender de sqlalchemy.Enum
# (que intentaría crear el tipo si la tabla no existe todavía).
class Script(Base):
    __tablename__ = "guiones"

    id_guion = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    numero_de_version = Column(
        String(45),
        nullable=False,
        unique=True
    )

    fecha_de_emision = Column(
        Date,
        nullable=False
    )

    estado = Column(
        String(50),
        nullable=False
    )

    # Legacy: campo de texto libre (nombre/URL) de cuando no había carga
    # real de archivo. Se deja nullable por compatibilidad con lo que ya
    # exista; el PDF real ahora vive en archivo_contenido.
    archivo = Column(
        Text,
        nullable=True
    )

    nombre = Column(
        String(100),
        nullable=False
    )

    descripcion = Column(
        Text
    )

    # ==========================================
    # PDF real del guión. Se sube con POST /scripts/{id}/archivo y se
    # sirve con GET /scripts/{id}/archivo — nunca viaja dentro del JSON
    # normal de /scripts para no inflar esas respuestas.
    #
    # El binario NO vive en Postgres: se sube al bucket "guiones" de
    # MinIO (ver app/utils/minio_client.py) y acá solo se guarda la
    # ruta del objeto (archivo_key). Antes esto era una columna BYTEA
    # (archivo_contenido) directo en esta tabla.
    # ==========================================
    archivo_nombre = Column(String(255), nullable=True)
    archivo_key = Column(Text, nullable=True)
    archivo_tipo = Column(String(100), nullable=True)
    archivo_tamano = Column(Integer, nullable=True)

    # index=True: listado principal de la pantalla Guión es por proyecto
    # (ver sql/022_indices_faltantes.sql).
    id_project = Column(  # llave foránea -> projects.id_project
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
