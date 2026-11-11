"""
Capa API — Contrato del "momento del día" entre el parser de guiones,
la API (SceneSchema) y la base de datos (ENUM momentodia).

Los tres deben aceptar los mismos valores; si no, una escena se puede
crear por un camino y no editar por otro. Los dos casos de abajo son
HALLAZGOS reales: xfail(strict=True) hace que el CI avise (en rojo)
cuando alguien los corrija, para quitar la marca.
"""
import typing

import pytest

from app.schemas.scene_schema import MomentoDia
from app.utils.script_parser import _MOMENTO_DIA_MAP

# Valores del ENUM "momentodia" en PostgreSQL (sql/000_schema_completo.sql).
MOMENTO_DIA_EN_BD = {"dia", "noche", "amanecer", "atardecer", "amanecer/dia", "dia/noche"}


@pytest.mark.xfail(
    strict=True,
    reason="HALLAZGO: el parser guarda 'dia/noche' y 'amanecer/dia' (válidos en la BD), "
           "pero SceneSchema no los acepta: esas escenas no se pueden editar con PUT (422).",
)
def test_todo_momento_que_detecta_el_parser_se_puede_guardar_por_la_api():
    # Arrange
    permitidos_api = set(typing.get_args(MomentoDia))

    # Act
    producidos_parser = set(_MOMENTO_DIA_MAP.values())

    # Assert
    assert producidos_parser <= permitidos_api


@pytest.mark.xfail(
    strict=True,
    reason="HALLAZGO: SceneSchema (y la app) aceptan 'anochecer', pero el ENUM momentodia "
           "de PostgreSQL no: la API valida el dato y luego la BD responde 500.",
)
def test_todo_momento_que_acepta_la_api_existe_en_la_bd():
    assert set(typing.get_args(MomentoDia)) <= MOMENTO_DIA_EN_BD


def test_todo_momento_que_detecta_el_parser_existe_en_la_bd():
    # Este sí se cumple: el parser y la BD están alineados.
    assert set(_MOMENTO_DIA_MAP.values()) <= MOMENTO_DIA_EN_BD
