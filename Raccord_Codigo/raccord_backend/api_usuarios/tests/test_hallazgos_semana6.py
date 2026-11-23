"""Semana 6 — reglas de servicio nacidas de hallazgos con PostgreSQL real.

Cada una cubre el valor límite de un 500 que la BD real dejó al descubierto
(ver PRUEBAS_SEMANA_6.md): antes de la regla, estos valores llegaban a la BD y
volvían como "INTERNAL_SERVER_ERROR".
"""
import pytest
from pydantic import ValidationError

from app.schemas.character_schema import EDAD_MAX, EDAD_MIN, CharacterSchema, CharacterUpdateSchema

PROYECTO = "11111111-1111-1111-1111-111111111111"


def _crear(**cambios):
    datos = dict(nombre="Laura", edad=30, codigo_personaje="P-01", id_project=PROYECTO)
    datos.update(cambios)
    return CharacterSchema(**datos)


@pytest.mark.parametrize("edad", [EDAD_MIN, EDAD_MAX])
def test_edad_en_los_limites_se_acepta(edad):
    assert _crear(edad=edad).edad == edad


@pytest.mark.parametrize("edad", [EDAD_MIN - 1, EDAD_MAX + 1, 3_000_000_000])
def test_edad_fuera_de_rango_se_rechaza(edad):
    with pytest.raises(ValidationError):
        _crear(edad=edad)


def test_actualizar_edad_fuera_de_rango_se_rechaza():
    with pytest.raises(ValidationError):
        CharacterUpdateSchema(edad=EDAD_MAX + 1)


@pytest.mark.parametrize("id_project", ["abc", "", "1111", PROYECTO + "x"])
def test_id_project_que_no_es_uuid_se_rechaza(id_project):
    with pytest.raises(ValidationError):
        _crear(id_project=id_project)
