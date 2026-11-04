import uuid
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# GALLERY PHOTO MODEL (tabla "fotos_continuidad")
# ==========================================
# Fotos de continuidad visual asociadas a una escena (mockup 6.1):
# vestuario, maquillaje, props, set, etc. La imagen se sube al bucket
# "imagenes" de MinIO (mismo patrón que el PDF de guiones en el bucket
# "guiones" — ver script_model.py y app/utils/minio_client.py); acá
# solo se guarda la ruta del objeto (archivo_key). Se sube con
# POST /scenes/{id_escena}/fotos y se sirve con
# GET /fotos/{id_foto}/archivo, nunca dentro del JSON normal de la
# lista (para no inflar esas respuestas).
#
# A diferencia de escenas/personajes/departamentos, esta tabla es
# nueva y no tiene un trigger de Postgres para generar su id, así que
# usa un autoincrement normal de SQLAlchemy (igual que "guiones").
class GalleryPhoto(Base):
    __tablename__ = "fotos_continuidad"

    id_foto = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    id_escena = Column(  # llave foránea -> escenas.id_escena
        UUID(as_uuid=True),
        ForeignKey("escenas.id_escena", ondelete="CASCADE"),
        nullable=False
    )

    # Tipo de foto: Locación, Propuesta, Prueba, En Rodaje — texto libre
    # validado del lado de la API (ver TIPOS_FOTO en
    # gallery_photo_schema.py).
    tipo_foto = Column(
        String(30),
        nullable=False,
        server_default="Propuesta"
    )

    # Código del personaje al que aplica esta foto (ej. "P001"), texto
    # libre igual que en el mockup — no es FK a personajes porque no
    # siempre una foto de continuidad corresponde a un personaje
    # (puede ser del set, de un prop, etc.).
    personaje_codigo = Column(
        String(30),
        nullable=True
    )

    descripcion = Column(
        Text,
        nullable=True
    )

    notas_continuidad = Column(
        Text,
        nullable=True
    )

    archivo_nombre = Column(String(255), nullable=False)
    archivo_key = Column(Text, nullable=False)
    archivo_tipo = Column(String(100), nullable=False)
    archivo_tamano = Column(Integer, nullable=False)

    fecha_subida = Column(
        DateTime,
        nullable=False,
        server_default=func.now()
    )

    # Papelera de reciclaje: Onset/Jefe de Departamento/Director pueden
    # mover una foto acá (soft-delete, ver "delete_photos" en
    # permissions.py); solo Jefe de Departamento y Director pueden
    # restaurarla o eliminarla DEFINITIVAMENTE (ver "manage_recycle_bin").
    # El Administrador puede ver la papelera pero no actuar sobre ella.
    # Mientras eliminada=True, la foto se oculta de los listados
    # normales (ver get_photos_by_scene/get_all_photos).
    eliminada = Column(Boolean, nullable=False, server_default="false")

    fecha_eliminacion = Column(DateTime, nullable=True)

    eliminada_por = Column(  # llave foránea -> users.id_user (informativo, quién la borró)
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="SET NULL"),
        nullable=True
    )
