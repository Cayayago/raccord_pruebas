from pydantic import BaseModel
from typing import Literal, Optional

# Estados posibles de un proyecto y causales de suspensión.
# Ver sql/028_proyecto_estado.sql.
EstadoProyecto = Literal["preliminar", "en_rodaje", "suspendido", "finalizado"]
CausalSuspension = Literal["temporal", "indefinido", "incumplimiento"]


class ProjectUpdateSchema(BaseModel):
    project_name: Optional[str] = None
    formato_de_produccion: Optional[str] = None
    genero: Optional[str] = None
    sinopsis: Optional[str] = None
    director: Optional[str] = None
    id_client: Optional[str] = None
    estado: Optional[EstadoProyecto] = None
    causal_suspension: Optional[CausalSuspension] = None


class ProjectSchema(BaseModel):
    id_project: Optional[str] = None
    project_name: str
    formato_de_produccion: str
    genero: str
    sinopsis: Optional[str] = None
    director: Optional[str] = None
    id_client: str
    estado: Optional[EstadoProyecto] = None
    causal_suspension: Optional[CausalSuspension] = None


class ProjectCreateSchema(BaseModel):
    project_name: str
    formato_de_produccion: str
    genero: str
    sinopsis: Optional[str] = None
    director: Optional[str] = None
    id_client: str
    id_user: str
    estado: Optional[EstadoProyecto] = None
    causal_suspension: Optional[CausalSuspension] = None
