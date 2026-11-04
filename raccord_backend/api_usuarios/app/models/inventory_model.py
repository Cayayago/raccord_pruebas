import uuid
from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base


# ==========================================
# INVENTORY MODEL (tabla "inventario")
# ==========================================
# Módulo Inventario: elementos físicos de la producción (vestuario,
# utilería, joyas, decoración...) con su foto. La imagen va al bucket
# "imagenes" de MinIO (mismo patrón que fotos_continuidad); acá solo se
# guarda la ruta del objeto (archivo_key).
#
# `codigo` es el código VISIBLE (lo digita la persona o se autogenera
# como INV-0001...). NO es la llave primaria: la PK es id_item (UUID) y
# el código solo debe ser único dentro del mismo proyecto.
class InventoryItem(Base):
    __tablename__ = "inventario"
    __table_args__ = (
        UniqueConstraint("id_project", "codigo", name="uq_inventario_project_codigo"),
    )

    id_item = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)

    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    codigo = Column(String(30), nullable=False)

    # Prenda inferior, Prenda superior, Zapatos, Abrigos, Utilería...
    tipo = Column(String(40), nullable=False)

    color_predominante = Column(String(30), nullable=True)
    genero = Column(String(15), nullable=True)  # Masculino | Femenino

    descripcion = Column(Text, nullable=True)
    cantidad = Column(Integer, nullable=False, server_default="1")

    # Texto libre: "Propio", "Bodega X", etc.
    origen = Column(Text, nullable=True)
    # Texto libre: "Venta", "Devuelto", "Departamento de Arte", etc.
    destino = Column(Text, nullable=True)
    composicion = Column(Text, nullable=True)  # ej. "100% algodón"

    # Fecha de ingreso del elemento: por defecto hoy, editable.
    fecha_ingreso = Column(Date, nullable=False, server_default=func.current_date())

    # Departamento al que pertenece el artículo (opcional).
    id_departamento = Column(
        UUID(as_uuid=True),
        ForeignKey("departamentos.id_departamento", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # LEGADO: antes el elemento tenía UNA sola foto aquí. Ahora las fotos
    # (hasta 3, individuales) viven en la tabla "inventario_fotos"; estas
    # columnas solo se leen para migrar automáticamente las fotos viejas
    # (ver _migrar_legado en inventory_controller.py).
    archivo_nombre = Column(String(255), nullable=True)
    archivo_key = Column(Text, nullable=True)
    archivo_tipo = Column(String(100), nullable=True)
    archivo_tamano = Column(Integer, nullable=True)

    fecha_creacion = Column(DateTime, nullable=False, server_default=func.now())
    fecha_actualizacion = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    creado_por = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id_user", ondelete="SET NULL"),
        nullable=True,
    )


# Fotos de un elemento: máximo MAX_FOTOS (3) por elemento, cada una
# individual (sin collage) — p. ej. frente, atrás y detalle.
class InventoryPhoto(Base):
    __tablename__ = "inventario_fotos"

    id_foto = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)

    id_item = Column(
        UUID(as_uuid=True),
        ForeignKey("inventario.id_item", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    orden = Column(Integer, nullable=False, server_default="1")

    archivo_nombre = Column(String(255), nullable=False)
    archivo_key = Column(Text, nullable=False)
    archivo_tipo = Column(String(100), nullable=False)
    archivo_tamano = Column(Integer, nullable=False)

    fecha_subida = Column(DateTime, nullable=False, server_default=func.now())
