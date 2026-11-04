from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# Catálogo de tipos de foto de continuidad (mockup 6.1, dropdown "Tipo
# de Foto"). Se valida como texto libre en los Form(...) de la ruta de
# subida (multipart no permite un Literal de Pydantic ahí directo),
# así que este catálogo queda documentado acá como referencia para el
# frontend, no como validación estricta del backend.
TIPOS_FOTO = ["Locación", "Propuesta", "Prueba", "En Rodaje"]


# ==========================================
# FOTO DE CONTINUIDAD - metadatos (respuesta)
# ==========================================
# Nunca incluye el binario (archivo_contenido) — eso se descarga aparte
# con GET /fotos/{id_foto}/archivo.
class GalleryPhotoOut(BaseModel):
    id_foto: str
    id_escena: str
    tipo_foto: str
    personaje_codigo: Optional[str] = None
    descripcion: Optional[str] = None
    notas_continuidad: Optional[str] = None
    archivo_nombre: str
    archivo_tamano: int
    fecha_subida: Optional[datetime] = None


# ==========================================
# FOTO DE CONTINUIDAD - edición de detalles (PATCH)
# ==========================================
# Todos opcionales a propósito: el visor estilo Polaroid del frontend
# guarda solo los campos que el usuario efectivamente cambió (edición
# parcial), nunca reemplaza la foto en sí ni archivo_nombre/tamaño —
# eso sigue siendo exclusivo de subir una foto nueva.
class GalleryPhotoUpdateSchema(BaseModel):
    tipo_foto: Optional[str] = None
    personaje_codigo: Optional[str] = None
    descripcion: Optional[str] = None
    notas_continuidad: Optional[str] = None
