from pydantic import BaseModel
from typing import Optional, Literal

# Categorías del desglose de producción (Props, Extras, SFX, etc.),
# tomadas del plan de rodaje / stripboard real que maneja el proyecto.
# "Cast" no está acá: el elenco de cada escena se maneja aparte, por la
# relación escenas_personajes (todavía no implementada).
Categoria = Literal[
    "Props",
    "Extras",
    "Bits",
    "SFX",
    "Sonido",
    "Stunts",
    "Vestuario",
    "Maquillaje/Pelo",
    "Maquillaje FX",
    "Cámara",
    "VFX",
    "Armas",
    "Vehículos",
    "Animales",
    "Arte",
    "Música",
    "Crew Adicional",
    "Notas"
]

Estado = Literal["pendiente", "en_progreso", "completado"]
Prioridad = Literal["alta", "media", "baja"]


# ==========================================
# DESGLOSE - NIVEL GENERAL
# ==========================================
class DesgloseItemSchema(BaseModel):
    id_escena: str
    id_departamento: Optional[str] = None
    categoria: Categoria
    nombre_item: str
    cantidad: Optional[int] = None
    notas: Optional[str] = None


class DesgloseItemUpdateSchema(BaseModel):
    id_escena: Optional[str] = None
    id_departamento: Optional[str] = None
    categoria: Optional[Categoria] = None
    nombre_item: Optional[str] = None
    cantidad: Optional[int] = None
    notas: Optional[str] = None


# ==========================================
# DESGLOSE - NIVEL ESPECIFICO (segmentación por departamento)
# ==========================================
class DesgloseDetalleSchema(BaseModel):
    etiqueta: str
    cantidad: Optional[int] = None
    estado: Estado = "pendiente"
    prioridad: Optional[Prioridad] = None
    notas: Optional[str] = None


class DesgloseDetalleUpdateSchema(BaseModel):
    etiqueta: Optional[str] = None
    cantidad: Optional[int] = None
    estado: Optional[Estado] = None
    prioridad: Optional[Prioridad] = None
    notas: Optional[str] = None
