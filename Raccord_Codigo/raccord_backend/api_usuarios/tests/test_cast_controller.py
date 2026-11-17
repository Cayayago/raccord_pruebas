"""
Capa API — Reparto (cast) de una escena
(app/controllers/scene_character_controller.py).

Reglas de negocio: un personaje solo puede entrar al cast de una escena
de SU MISMO proyecto, y no puede repetirse en la misma escena.
"""
import pytest

from app.controllers.scene_character_controller import (
    add_character_to_scene,
    get_cast_by_scene,
    remove_character_from_scene,
)
from app.models.character_model import Character
from app.models.scene_character_model import SceneCharacter
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.schemas.scene_character_schema import SceneCharacterSchema
from tests.fakes import FakeSession, Obj

ESCENA = Obj(id_escena="esc-1", id_guion="guion-1")
PERSONAJE_PROYECTO_A = Obj(id_personaje="per-1", nombre="ELENA", edad=30, codigo_personaje="P001", id_project="proj-A")


def _db(escena=ESCENA, personaje=PERSONAJE_PROYECTO_A, proyecto_escena="proj-A", ya_en_cast=None):
    return FakeSession({
        Scene: escena,
        Character: personaje,
        Script.id_project: proyecto_escena,
        SceneCharacter: ya_en_cast,
    })


def test_add_character_to_scene_creates_link_when_same_project():
    # Arrange
    db = _db()

    # Act
    resp = add_character_to_scene("esc-1", SceneCharacterSchema(id_personaje="per-1"), db)

    # Assert
    assert resp["success"] is True
    assert len(db.added) == 1
    assert db.added[0].id_personaje == "per-1"
    assert db.commits == 1


def test_add_character_to_scene_rejects_character_from_another_project():
    # Arrange: el personaje es del proyecto A y la escena del proyecto B
    db = _db(proyecto_escena="proj-B")

    # Act
    resp = add_character_to_scene("esc-1", SceneCharacterSchema(id_personaje="per-1"), db)

    # Assert
    assert resp["success"] is False
    assert resp["error"] == "CROSS_PROJECT_CHARACTER"
    assert db.added == []


def test_add_character_to_scene_rejects_scene_without_script():
    # Una escena sin guion no tiene proyecto: no se puede validar el cruce
    db = _db(escena=Obj(id_escena="esc-1", id_guion=None))

    resp = add_character_to_scene("esc-1", SceneCharacterSchema(id_personaje="per-1"), db)

    assert resp["error"] == "CROSS_PROJECT_CHARACTER"


def test_add_character_to_scene_rejects_duplicate():
    db = _db(ya_en_cast=Obj(id_escena="esc-1", id_personaje="per-1"))

    resp = add_character_to_scene("esc-1", SceneCharacterSchema(id_personaje="per-1"), db)

    assert resp["success"] is False
    assert resp["error"] == "ALREADY_IN_CAST"
    assert db.added == []


@pytest.mark.parametrize(
    "escena, personaje, mensaje",
    [(None, PERSONAJE_PROYECTO_A, "Escena no encontrada"), (ESCENA, None, "Personaje no encontrado")],
)
def test_add_character_to_scene_fails_when_scene_or_character_does_not_exist(escena, personaje, mensaje):
    resp = add_character_to_scene("esc-1", SceneCharacterSchema(id_personaje="per-1"), _db(escena=escena, personaje=personaje))

    assert resp["success"] is False
    assert resp["message"] == mensaje


def test_get_cast_by_scene_returns_serialized_characters():
    db = FakeSession({
        Scene: ESCENA,
        SceneCharacter: [Obj(id_personaje="per-1")],
        Character: [PERSONAJE_PROYECTO_A],
    })

    resp = get_cast_by_scene("esc-1", db)

    assert resp["data"] == [{"id_personaje": "per-1", "nombre": "ELENA", "edad": 30, "codigo_personaje": "P001"}]


def test_get_cast_by_scene_returns_empty_list_when_no_one_is_cast():
    resp = get_cast_by_scene("esc-1", FakeSession({Scene: ESCENA, SceneCharacter: []}))

    assert resp["success"] is True
    assert resp["data"] == []


def test_get_cast_by_scene_fails_when_scene_does_not_exist():
    assert get_cast_by_scene("x", FakeSession())["success"] is False


def test_remove_character_from_scene_deletes_existing_link():
    link = Obj(id_escena="esc-1", id_personaje="per-1")
    db = FakeSession({SceneCharacter: link})

    resp = remove_character_from_scene("esc-1", "per-1", db)

    assert resp["success"] is True
    assert db.deleted == [link]


def test_remove_character_from_scene_fails_when_not_in_cast():
    resp = remove_character_from_scene("esc-1", "per-1", FakeSession())

    assert resp["success"] is False
