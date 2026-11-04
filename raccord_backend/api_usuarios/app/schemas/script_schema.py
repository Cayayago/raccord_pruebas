from pydantic import BaseModel
from typing import Optional, Literal
from datetime import date

# Debe coincidir exactamente con el ENUM estado_guion de la BD.
EstadoGuion = Literal["Borrador", "Revisión", "Aprobado", "En Rodaje", "Archivado"]


# ==========================================
# GUIONES
# ==========================================
class ScriptSchema(BaseModel):
    numero_de_version: str
    fecha_de_emision: date
    estado: EstadoGuion
    # Ya no es obligatorio: el PDF real se sube aparte con
    # POST /scripts/{id}/archivo justo después de crear el guión. Este
    # campo queda como texto libre opcional (legado).
    archivo: Optional[str] = ""
    nombre: str
    descripcion: Optional[str] = None
    id_project: Optional[str] = None


class ScriptUpdateSchema(BaseModel):
    numero_de_version: Optional[str] = None
    fecha_de_emision: Optional[date] = None
    estado: Optional[EstadoGuion] = None
    archivo: Optional[str] = None
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    id_project: Optional[str] = None


# ==========================================
# SEGMENTACIÓN AUTOMÁTICA POR ESCENAS
# ==========================================
# confirmar=False (default): solo analiza el PDF y devuelve una vista
# previa de las escenas/personajes detectados, SIN escribir en la BD.
# confirmar=True: repite el mismo análisis y esta vez sí crea las
# escenas. Se re-analiza en vez de guardar un resultado intermedio en
# sesión porque el parseo es barato (texto + regex, sin IA de por
# medio) y así el endpoint queda sin estado entre llamadas.
class SegmentarScriptSchema(BaseModel):
    confirmar: bool = False
