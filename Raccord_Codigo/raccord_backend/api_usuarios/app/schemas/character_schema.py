from pydantic import BaseModel, Field
from typing import Optional

# Límites de las columnas de "personajes" (ver character_model.py). Sin
# ellos, un valor más largo pasaba la validación, PostgreSQL lo rechazaba
# al guardar ("value too long") y la persona recibía un 500 genérico en
# vez de un 422 que dijera qué campo estaba mal.
NOMBRE_MAX = 45
CODIGO_MAX = 30


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
    nombre: str = Field(max_length=NOMBRE_MAX)
    edad: int
    codigo_personaje: str = Field(max_length=CODIGO_MAX)
    id_project: str


class CharacterUpdateSchema(BaseModel):
    nombre: Optional[str] = Field(default=None, max_length=NOMBRE_MAX)
    edad: Optional[int] = None
    codigo_personaje: Optional[str] = Field(default=None, max_length=CODIGO_MAX)
