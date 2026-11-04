from pydantic import BaseModel
from typing import Optional


# ==========================================
# DEPARTAMENTOS
# ==========================================
# id_departamento no va en el schema de creación: lo genera el trigger
# de la base de datos (area01, area02, ...).
class DepartmentSchema(BaseModel):
    nombre: str
    ubicacion: str


class DepartmentUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    ubicacion: Optional[str] = None
