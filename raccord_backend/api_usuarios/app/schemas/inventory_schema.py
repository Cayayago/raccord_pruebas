from datetime import date
from typing import Optional

from pydantic import BaseModel, field_validator

# Catálogos de referencia (el frontend tiene su propia copia para armar
# las listas desplegables; acá se documentan y se usan para validar el
# género). Tipo y color se guardan como texto para poder agregar nuevos
# sin migrar nada.
GENEROS_INVENTARIO = ["Masculino", "Femenino"]

TIPOS_INVENTARIO = [
    "Prenda superior", "Prenda inferior", "Vestido", "Traje completo", "Abrigos", "Zapatos",
    "Joyas", "Accesorios", "Sombreros y gorras", "Bolsos y maletas",
    "Utilería", "Decoración", "Utensilio", "Mobiliario", "Electrónicos",
    "Documentos y papelería", "Libros y arte", "Herramientas", "Instrumentos musicales",
    "Armas y utilería de acción", "Vehículos", "Alimentos y bebidas (props)",
    "Maquillaje y peluquería", "Textiles y telas", "Iluminación",
    "Productos de aseo", "Materiales", "Otros",
]


def _vacio_a_none(v):
    if isinstance(v, str):
        v = v.strip()
        return v or None
    return v


class InventoryUpdateSchema(BaseModel):
    """PATCH /inventario/{id_item}: edición parcial (exclude_unset)."""
    codigo: Optional[str] = None
    tipo: Optional[str] = None
    color_predominante: Optional[str] = None
    genero: Optional[str] = None
    descripcion: Optional[str] = None
    cantidad: Optional[int] = None
    origen: Optional[str] = None
    destino: Optional[str] = None
    composicion: Optional[str] = None
    id_departamento: Optional[str] = None
    fecha_ingreso: Optional[date] = None

    @field_validator(
        "codigo", "tipo", "color_predominante", "genero", "descripcion",
        "origen", "destino", "composicion", "id_departamento",
        mode="before",
    )
    @classmethod
    def limpiar(cls, v):
        return _vacio_a_none(v)

    @field_validator("genero")
    @classmethod
    def genero_valido(cls, v):
        if v is not None and v not in GENEROS_INVENTARIO:
            raise ValueError(f"Género inválido. Use: {', '.join(GENEROS_INVENTARIO)}")
        return v

    @field_validator("cantidad")
    @classmethod
    def cantidad_valida(cls, v):
        if v is not None and v < 0:
            raise ValueError("La cantidad no puede ser negativa")
        return v
