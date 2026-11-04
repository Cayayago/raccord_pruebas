from pydantic import BaseModel
from typing import Optional


# ==========================================
# PERSONAJES
# ==========================================
# id_personaje no va en el schema de creación: lo genera el trigger de
# la base de datos (cast1, cast2, ...).
#
# id_project es obligatorio a propósito (ver sql/015_project_scoping.sql):
# todo personaje NUEVO debe quedar amarrado a un proyecto desde que se
# crea, para que Escenas/Desglose de OTROS proyectos nunca puedan verlo
# ni asignarlo. No se permite cambiarlo después (no está en
# CharacterUpdateSchema) — mover un personaje de proyecto no es un caso
# de uso real y evita huecos de seguridad por PATCH.
class CharacterSchema(BaseModel):
    nombre: str
    edad: int
    codigo_personaje: str
    id_project: str


class CharacterUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    edad: Optional[int] = None
    codigo_personaje: Optional[str] = None
