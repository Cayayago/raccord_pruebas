"""Semana 6 (capa BD, Deiver) — reglas unitarias en el valor límite.

Cada regla corrige un 500 que solo apareció contra PostgreSQL real
(tests/integracion/test_bd_escenas.py). Aquí se prueba la regla sola, sin BD;
el test de integración queda como red.
"""
import uuid

import pytest
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from app.schemas.scene_schema import ENTERO_MAX, NUMERO_ESCENA_MAX, SceneSchema, SceneUpdateSchema
from tests.fakes import FakeSession

BASE = {"numero_de_escena": "1", "encabezado": "INT. CASA - DIA"}


# --- numero_de_escena: varchar(45), no vacío -------------------------
@pytest.mark.parametrize("largo", [1, NUMERO_ESCENA_MAX])
def test_scene_number_inside_the_column_limit_is_accepted(largo):
    assert SceneSchema(**{**BASE, "numero_de_escena": "9" * largo})


@pytest.mark.parametrize("valor", ["", "9" * (NUMERO_ESCENA_MAX + 1)])
def test_scene_number_empty_or_over_45_chars_is_rejected(valor):
    with pytest.raises(ValidationError):
        SceneSchema(**{**BASE, "numero_de_escena": valor})
    with pytest.raises(ValidationError):
        SceneUpdateSchema(numero_de_escena=valor)


# --- enteros: integer de PostgreSQL y no negativos ---------------------
@pytest.mark.parametrize("campo", ["pagina", "dia_dramatico", "orden_rodaje", "bloque_grabacion"])
@pytest.mark.parametrize("valor", [0, ENTERO_MAX])
def test_integer_fields_accept_the_limits(campo, valor):
    assert getattr(SceneSchema(**{**BASE, campo: valor}), campo) == valor


@pytest.mark.parametrize("campo", ["pagina", "dia_dramatico", "orden_rodaje", "bloque_grabacion"])
@pytest.mark.parametrize("valor", [-1, ENTERO_MAX + 1, 3_000_000_000])
def test_integer_fields_reject_negative_or_overflowing_values(campo, valor):
    with pytest.raises(ValidationError):
        SceneSchema(**{**BASE, campo: valor})
    with pytest.raises(ValidationError):
        SceneUpdateSchema(**{campo: valor})


# --- ids: uuid o nada ----------------------------------------------------
@pytest.mark.parametrize("campo", ["id_guion", "id_rodaje", "id_desglose"])
def test_ids_accept_a_uuid_or_nothing(campo):
    valido = str(uuid.uuid4())
    assert getattr(SceneSchema(**{**BASE, campo: valido}), campo) == valido
    assert getattr(SceneUpdateSchema(**{campo: None}), campo) is None


@pytest.mark.parametrize("campo", ["id_guion", "id_rodaje", "id_desglose"])
@pytest.mark.parametrize("valor", ["abc", "", "1111", str(uuid.uuid4()) + "x"])
def test_ids_that_are_not_uuids_are_rejected(campo, valor):
    with pytest.raises(ValidationError):
        SceneSchema(**{**BASE, campo: valor})


# --- la BD rechaza el guardado: respuesta clara y rollback --------------
class _SesionQueRechaza(FakeSession):
    """Fake: el commit falla como lo haría PostgreSQL con una FK o UNIQUE."""

    def commit(self):
        raise IntegrityError("INSERT ...", {}, Exception("violates foreign key constraint"))


def test_create_scene_with_a_reference_that_does_not_exist_answers_invalid_reference():
    from app.controllers.scene_controller import create_scene

    db = _SesionQueRechaza()
    respuesta = create_scene(SceneSchema(**BASE, id_guion=str(uuid.uuid4()), id_rodaje=str(uuid.uuid4())), db)

    assert respuesta["error"] == "INVALID_REFERENCE"
    assert db.rollbacks == 1


def test_create_script_rejected_by_the_unique_constraint_answers_duplicate_version():
    from app.controllers.script_controller import create_script
    from app.models.script_model import Script
    from app.schemas.script_schema import ScriptSchema

    db = _SesionQueRechaza({Script: None})  # la consulta previa no ve duplicados (carrera)
    cuerpo = ScriptSchema(
        numero_de_version="V2", fecha_de_emision="2026-11-24", estado="Borrador",
        nombre="Guion", id_project=str(uuid.uuid4()),
    )

    respuesta = create_script(cuerpo, db)

    assert respuesta["error"] == "DUPLICATE_VERSION"
    assert db.rollbacks == 1
