from pydantic import BaseModel
from typing import Optional
from datetime import time


# ==========================================
# DESGLOSE - CONTENEDOR (tabla "desgloses")
# ==========================================
# id_desglose no va en el schema de creación: lo genera la BD
# ('desg' + consecutivo).
class BreakdownSheetSchema(BaseModel):
    version: str
    semana_grabacion: Optional[int] = None
    dia_rodaje: Optional[int] = None
    hora_inicio: Optional[time] = None
    hora_fin: Optional[time] = None
    location: Optional[str] = None
    requerimientos: str
    activo: Optional[bool] = True
    # Obligatorio (ver sql/015_project_scoping.sql): un contenedor de
    # desglose siempre pertenece a UN proyecto, incluso antes de
    # asignarle escenas. No se puede cambiar después.
    id_project: str


class BreakdownSheetUpdateSchema(BaseModel):
    version: Optional[str] = None
    semana_grabacion: Optional[int] = None
    dia_rodaje: Optional[int] = None
    hora_inicio: Optional[time] = None
    hora_fin: Optional[time] = None
    location: Optional[str] = None
    requerimientos: Optional[str] = None
    activo: Optional[bool] = None
