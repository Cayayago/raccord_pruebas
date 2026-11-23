from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

# Límites de las columnas de "personajes" (ver character_model.py). Sin
# ellos, un valor más largo pasaba la validación, PostgreSQL lo rechazaba
# al guardar ("value too long") y la persona recibía un 500 genérico en
# vez de un 422 que dijera qué campo estaba mal.
NOMBRE_MAX = 45
CODIGO_MAX = 30

# Semana 6 (hallazgos con PostgreSQL real): edad cabe en un integer de 4 bytes
# pero 3.000.000.000 lo desbordaba (500 "integer out of range"). Una edad de
# personaje real está en este rango; fuera de él se responde 422.
EDAD_MIN = 0
EDAD_MAX = 120


def validar_uuid(valor: str) -> str:
    """id_project llega como texto; PostgreSQL lo castea a uuid y con un texto
    cualquiera ("abc") la consulta fallaba con 500. Se rechaza antes con 422."""
    try:
        UUID(str(valor))
    except ValueError:
        raise ValueError("id_project debe ser un UUID válido")
    return valor


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
    edad: int = Field(ge=EDAD_MIN, le=EDAD_MAX)
    codigo_personaje: str = Field(max_length=CODIGO_MAX)
    id_project: str

    _id_project_uuid = field_validator("id_project")(validar_uuid)


class CharacterUpdateSchema(BaseModel):
    nombre: Optional[str] = Field(default=None, max_length=NOMBRE_MAX)
    edad: Optional[int] = Field(default=None, ge=EDAD_MIN, le=EDAD_MAX)
    codigo_personaje: Optional[str] = Field(default=None, max_length=CODIGO_MAX)
