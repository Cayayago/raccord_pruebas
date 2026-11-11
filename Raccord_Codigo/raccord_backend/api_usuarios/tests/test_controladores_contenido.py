"""
Capa API — Escenas, personajes y plan de rodaje
(app/controllers/scene_controller.py, character_controller.py y
shooting_day_controller.py). Semana 3: backend al 40 %.

Reglas de negocio:
- Una escena no se puede crear sin guion ni moverse a un guion de OTRO proyecto.
- Un personaje con actores asignados no se puede eliminar.
- Un día de rodaje con escenas agendadas no se puede eliminar.
"""
from datetime import date, time

import pytest

from app.controllers import character_controller as personajes
from app.controllers import scene_controller as escenas
from app.controllers import shooting_day_controller as rodaje
from app.models.actor_model import Actor
from app.models.character_model import Character
from app.models.scene_character_model import SceneCharacter
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.shooting_day_model import ShootingDay
from app.schemas.character_schema import CharacterSchema, CharacterUpdateSchema
from app.schemas.scene_schema import SceneSchema, SceneUpdateSchema
from app.schemas.shooting_day_schema import ShootingDaySchema, ShootingDayUpdateSchema
from tests.fakes import FakeSession, Obj, Seq


def _escena(**cambios):
    datos = dict(id_escena="esc-1", numero_de_escena="1", encabezado="INT. CASA - DIA", id_guion="guion-A",
                 estado="Pendiente", fecha_de_grabacion=None, hora_inicio_rodaje=None)
    datos.update(cambios)
    return Scene(**datos)


# ---------- Escenas ----------

def test_create_scene_requires_script():
    # Arrange
    db = FakeSession()

    # Act
    resp = escenas.create_scene(SceneSchema(numero_de_escena="1", encabezado="INT. CASA - DIA"), db)

    # Assert
    assert resp["error"] == "MISSING_SCRIPT"
    assert db.added == []


def test_create_scene_saves_it_as_pending_by_default():
    db = FakeSession()

    resp = escenas.create_scene(SceneSchema(numero_de_escena="1", encabezado="INT. CASA - DIA", id_guion="guion-A"), db)

    assert resp["success"] is True
    assert db.added[0].estado == "Pendiente"
    assert db.commits == 1


def test_update_scene_rejects_moving_it_to_a_script_of_another_project():
    # Arrange: el guion actual es del proyecto A y el nuevo del proyecto B
    escena = _escena()
    db = FakeSession({Scene: escena, Script.id_project: Seq(["proj-A", "proj-B"])})

    # Act
    resp = escenas.update_scene("esc-1", SceneUpdateSchema(id_guion="guion-B"), db)

    # Assert
    assert resp["error"] == "CROSS_PROJECT_MOVE"
    assert escena.id_guion == "guion-A"  # no se movió
    assert db.commits == 0


def test_update_scene_allows_moving_it_to_another_script_of_the_same_project():
    escena = _escena()
    db = FakeSession({Scene: escena, Script.id_project: Seq(["proj-A", "proj-A"])})

    resp = escenas.update_scene("esc-1", SceneUpdateSchema(id_guion="guion-A2", estado="En proceso"), db)

    assert resp["success"] is True
    assert escena.id_guion == "guion-A2"
    assert escena.estado == "En proceso"


def test_update_scene_only_changes_the_fields_sent():
    escena = _escena(descripcion="original", ciudad="Bogotá")
    db = FakeSession({Scene: escena})

    escenas.update_scene("esc-1", SceneUpdateSchema(descripcion="nueva"), db)

    assert escena.descripcion == "nueva"
    assert escena.ciudad == "Bogotá"


def test_update_scene_full_rejects_cross_project_move_too():
    db = FakeSession({Scene: _escena(), Script.id_project: Seq(["proj-A", "proj-B"])})

    resp = escenas.update_scene_full(
        "esc-1", SceneSchema(numero_de_escena="1", encabezado="X", id_guion="guion-B"), db)

    assert resp["error"] == "CROSS_PROJECT_MOVE"


def test_update_scene_full_keeps_previous_state_when_none_is_sent():
    escena = _escena(estado="Finalizada")
    db = FakeSession({Scene: escena})

    resp = escenas.update_scene_full(
        "esc-1",
        SceneSchema(numero_de_escena="2", encabezado="EXT. CALLE - NOCHE", id_guion="guion-A", estado=None,
                    fecha_de_grabacion=date(2026, 11, 20), hora_inicio_rodaje=time(7, 30)),
        db,
    )

    assert escena.estado == "Finalizada"
    assert resp["data"]["fecha_de_grabacion"] == "2026-11-20"
    assert resp["data"]["hora_inicio_rodaje"] == "07:30:00"


def test_get_scenes_includes_the_cast_of_each_scene():
    # Arrange: dos escenas, solo la primera tiene a ELENA en el reparto
    db = FakeSession({
        Scene: [_escena(), _escena(id_escena="esc-2")],
        SceneCharacter: [Obj(id_escena="esc-1", id_personaje="per-1")],
        Character: [Obj(id_personaje="per-1", nombre="ELENA", edad=30, codigo_personaje="P001")],
    })

    # Act
    resp = escenas.get_scenes("proj-A", db)

    # Assert
    cast = {e["id_escena"]: e["cast"] for e in resp["data"]}
    assert [c["nombre"] for c in cast["esc-1"]] == ["ELENA"]
    assert cast["esc-2"] == []


@pytest.mark.parametrize("funcion", [escenas.get_scenes_by_script, escenas.get_scenes_by_rodaje, escenas.get_scenes_by_desglose])
def test_scene_listings_serialize_every_scene(funcion):
    resp = funcion("x", FakeSession({Scene: [_escena(), _escena(id_escena="esc-2")]}))

    assert [e["id_escena"] for e in resp["data"]] == ["esc-1", "esc-2"]


@pytest.mark.parametrize(
    "accion",
    [
        lambda db: escenas.get_scene("x", db),
        lambda db: escenas.delete_scene("x", db),
        lambda db: escenas.update_scene("x", SceneUpdateSchema(), db),
        lambda db: escenas.update_scene_full("x", SceneSchema(numero_de_escena="1", encabezado="X"), db),
    ],
)
def test_scene_operations_fail_when_scene_does_not_exist(accion):
    assert accion(FakeSession())["message"] == "Escena no encontrada"


def test_delete_scene_removes_it():
    escena = _escena()
    db = FakeSession({Scene: escena})

    resp = escenas.delete_scene("esc-1", db)

    assert resp["success"] is True
    assert db.deleted == [escena]


def test_get_scene_returns_serialized_scene():
    assert escenas.get_scene("esc-1", FakeSession({Scene: _escena()}))["data"]["encabezado"] == "INT. CASA - DIA"


# ---------- Personajes ----------

def _personaje(**cambios):
    datos = dict(id_personaje="per-1", nombre="ELENA", edad=30, codigo_personaje="P001", id_project="proj-A")
    datos.update(cambios)
    return Character(**datos)


def test_delete_character_is_blocked_when_it_has_actors():
    # Arrange
    personaje = _personaje()
    db = FakeSession({Character: personaje, Actor: [Obj(id_actor="a1")]})

    # Act
    resp = personajes.delete_character("per-1", db)

    # Assert
    assert resp["error"] == "CHARACTER_HAS_ACTORS"
    assert "1 actor(es)" in resp["message"]
    assert db.deleted == []


def test_delete_character_reports_scenes_it_was_removed_from():
    personaje = _personaje()
    db = FakeSession({Character: personaje, Actor: [], SceneCharacter: [Obj(), Obj()]})

    resp = personajes.delete_character("per-1", db)

    assert db.deleted == [personaje]
    assert resp["message"] == "Personaje eliminado (también se quitó del cast de 2 escena(s))"


def test_delete_character_without_scenes_uses_short_message():
    resp = personajes.delete_character("per-1", FakeSession({Character: _personaje(), Actor: [], SceneCharacter: []}))

    assert resp["message"] == "Personaje eliminado"


def test_get_character_includes_its_actors():
    db = FakeSession({Character: _personaje(), Actor: [Obj(id_actor="a1", nombre="Ana", apellido="Ruiz", genero="otro")]})

    resp = personajes.get_character("per-1", db)

    assert resp["data"]["actores"] == [{"id_actor": "a1", "nombre": "Ana", "apellido": "Ruiz", "genero": "otro"}]


def test_create_and_list_characters():
    db = FakeSession({Character: [_personaje()]})

    creado = personajes.create_character(CharacterSchema(nombre="JULIÁN", edad=45, codigo_personaje="P002", id_project="proj-A"), db)
    lista = personajes.get_characters("proj-A", db)

    assert creado["data"]["nombre"] == "JULIÁN"
    assert [c["nombre"] for c in lista["data"]] == ["ELENA"]


def test_update_character_full_does_not_change_project():
    personaje = _personaje()
    db = FakeSession({Character: personaje})

    personajes.update_character_full("per-1", CharacterSchema(nombre="ELENA M", edad=31, codigo_personaje="P001", id_project="otro"), db)

    assert personaje.nombre == "ELENA M"
    assert personaje.id_project == "proj-A"


def test_update_character_partial_only_changes_sent_fields():
    personaje = _personaje()

    personajes.update_character("per-1", CharacterUpdateSchema(edad=32), FakeSession({Character: personaje}))

    assert (personaje.nombre, personaje.edad) == ("ELENA", 32)


@pytest.mark.parametrize(
    "accion",
    [
        lambda db: personajes.get_character("x", db),
        lambda db: personajes.delete_character("x", db),
        lambda db: personajes.update_character("x", CharacterUpdateSchema(), db),
        lambda db: personajes.update_character_full("x", CharacterSchema(nombre="A", edad=1, codigo_personaje="P", id_project="p"), db),
    ],
)
def test_character_operations_fail_when_character_does_not_exist(accion):
    assert accion(FakeSession())["message"] == "Personaje no encontrado"


# ---------- Plan de rodaje ----------

def _dia(**cambios):
    datos = dict(id_rodaje="rod-1", version="v1", semana_grabacion=1, dia_rodaje=1, hora_inicio=time(6, 0),
                 hora_fin=None, location="Bogotá", notas=None, activo=True, id_project="proj-A")
    datos.update(cambios)
    return ShootingDay(**datos)


def test_delete_shooting_day_is_blocked_when_it_has_scenes():
    # Arrange
    dia = _dia()
    db = FakeSession({ShootingDay: dia, Scene: [_escena(), _escena(id_escena="esc-2")]})

    # Act
    resp = rodaje.delete_shooting_day("rod-1", db)

    # Assert
    assert resp["error"] == "SHOOTING_DAY_IN_USE"
    assert "2 escena(s)" in resp["message"]
    assert db.deleted == []


def test_delete_empty_shooting_day():
    dia = _dia()
    db = FakeSession({ShootingDay: dia, Scene: []})

    assert rodaje.delete_shooting_day("rod-1", db)["success"] is True
    assert db.deleted == [dia]


def test_create_shooting_day_is_active_by_default():
    db = FakeSession()

    resp = rodaje.create_shooting_day(ShootingDaySchema(version="v1", id_project="proj-A", activo=None), db)

    assert db.added[0].activo is True
    assert resp["data"]["id_project"] == "proj-A"


def test_get_shooting_day_includes_its_scenes_and_formats_hours():
    db = FakeSession({ShootingDay: _dia(), Scene: [_escena()]})

    resp = rodaje.get_shooting_day("rod-1", db)

    assert resp["data"]["hora_inicio"] == "06:00:00"
    assert resp["data"]["hora_fin"] is None
    assert [e["id_escena"] for e in resp["data"]["escenas"]] == ["esc-1"]


def test_update_shooting_day_full_and_partial():
    dia = _dia()
    db = FakeSession({ShootingDay: dia})

    rodaje.update_shooting_day_full("rod-1", ShootingDaySchema(version="v2", id_project="proj-A", activo=None, notas="Lluvia"), db)
    rodaje.update_shooting_day("rod-1", ShootingDayUpdateSchema(location="Medellín"), db)

    assert (dia.version, dia.activo, dia.notas, dia.location) == ("v2", True, "Lluvia", "Medellín")


def test_list_shooting_days():
    resp = rodaje.get_shooting_days("proj-A", FakeSession({ShootingDay: [_dia(), _dia(id_rodaje="rod-2")]}))

    assert [d["id_rodaje"] for d in resp["data"]] == ["rod-1", "rod-2"]


@pytest.mark.parametrize(
    "accion",
    [
        lambda db: rodaje.get_shooting_day("x", db),
        lambda db: rodaje.delete_shooting_day("x", db),
        lambda db: rodaje.update_shooting_day("x", ShootingDayUpdateSchema(), db),
        lambda db: rodaje.update_shooting_day_full("x", ShootingDaySchema(version="v", id_project="p"), db),
    ],
)
def test_shooting_day_operations_fail_when_day_does_not_exist(accion):
    assert accion(FakeSession())["message"] == "Día de rodaje no encontrado"
