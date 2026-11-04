from pydantic import BaseModel
from typing import Optional


# ==========================================
# CREW LIST (personal de producción)
# ==========================================
class CrewMemberSchema(BaseModel):
    nombre: str
    cargo: str
    id_departamento: Optional[str] = None
    celular: Optional[str] = None
    correo: Optional[str] = None
    notas: Optional[str] = None
    # Obligatorio (ver sql/015_project_scoping.sql): Crew List siempre
    # debe quedar amarrado a UN proyecto — antes se mezclaba el
    # personal de todos los proyectos. No se puede cambiar después.
    id_project: str


class CrewMemberUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    cargo: Optional[str] = None
    id_departamento: Optional[str] = None
    celular: Optional[str] = None
    correo: Optional[str] = None
    notas: Optional[str] = None
