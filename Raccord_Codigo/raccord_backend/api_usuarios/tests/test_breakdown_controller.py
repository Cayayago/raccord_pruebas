"""Semana 6 (cobertura) — reglas del controlador de desglose.

Reglas con consecuencias reales: cada departamento solo toca SU segmentación,
un ítem no se puede mover a una escena de otro proyecto y los pendientes se
listan por prioridad. Sin BD: FakeSession (ver tests/fakes.py).
"""
import pytest

from app.controllers import breakdown_controller as ctl
from app.models.breakdown_model import DesgloseItem, DesgloseItemDetalle
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.user_model import User
from app.schemas.breakdown_schema import (
    DesgloseDetalleSchema,
    DesgloseDetalleUpdateSchema,
    DesgloseItemSchema,
    DesgloseItemUpdateSchema,
)
from tests.fakes import FakeSession, Obj, Seq

MI_DEPTO = "dep-mio"
OTRO_DEPTO = "dep-otro"
YO = {"id_user": "u1"}


class Fila(Obj):
    def __getattr__(self, nombre):
        return None


def _item(**attrs):
    base = dict(id_desglose_item="i1", id_escena="e1", id_departamento=MI_DEPTO, categoria="Props", nombre_item="Taza")
    base.update(attrs)
    return Fila(**base)


def _detalle(**attrs):
    base = dict(id_detalle="d1", id_desglose_item="i1", etiqueta="Roja", estado="pendiente")
    base.update(attrs)
    return Fila(**base)


def _usuario(depto=MI_DEPTO):
    return Obj(id_departamento=depto)


def _db(resultados=None):
    return FakeSession({User: _usuario(), **(resultados or {})})


def _item_nuevo(id_escena="e1"):
    return DesgloseItemSchema(id_escena=id_escena, categoria="Props", nombre_item="Taza")


# ---------- ítems ----------
def test_listar_items_de_una_escena():
    resp = ctl.get_items_by_scene("e1", _db({DesgloseItem: [_item(), _item(id_desglose_item="i2")]}))

    assert [i["id_desglose_item"] for i in resp["data"]] == ["i1", "i2"]


def test_get_item_encontrado_y_no_encontrado():
    assert ctl.get_item("i1", _db({DesgloseItem: _item()}))["data"]["nombre_item"] == "Taza"
    assert ctl.get_item("x", _db({DesgloseItem: None}))["message"] == "Item de desglose no encontrado"


def test_crear_item_guarda_quien_lo_creo():
    db = _db()

    resp = ctl.create_item(_item_nuevo(), db, YO)

    assert db.commits == 1
    assert resp["data"]["id_user_creador"] == "u1"


def test_mover_item_a_escena_de_otro_proyecto_se_rechaza():
    item = _item(id_escena="e1")
    db = _db({DesgloseItem: item, Scene: Obj(id_guion="g"), Script.id_project: Seq(["proj-B", "proj-A"])})

    resp = ctl.update_item_full("i1", _item_nuevo("e2"), db)

    assert resp["error"] == "CROSS_PROJECT_MOVE"
    assert item.id_escena == "e1"


def test_mover_item_a_otra_escena_del_mismo_proyecto_se_permite():
    item = _item(id_escena="e1")
    db = _db({DesgloseItem: item, Scene: Obj(id_guion="g"), Script.id_project: Seq(["proj-A", "proj-A"])})

    resp = ctl.update_item_full("i1", _item_nuevo("e2"), db)

    assert resp["success"] is True
    assert item.id_escena == "e2"


def test_actualizar_item_parcial_tambien_bloquea_el_cambio_de_proyecto():
    item = _item(id_escena="e1")
    db = _db({DesgloseItem: item, Scene: Obj(id_guion="g"), Script.id_project: Seq(["proj-B", "proj-A"])})

    resp = ctl.update_item("i1", DesgloseItemUpdateSchema(id_escena="e2"), db)

    assert resp["error"] == "CROSS_PROJECT_MOVE"


def test_actualizar_item_parcial_cambia_solo_lo_enviado():
    item = _item(notas="vieja")

    ctl.update_item("i1", DesgloseItemUpdateSchema(cantidad=3), _db({DesgloseItem: item}))

    assert (item.cantidad, item.notas) == (3, "vieja")


def test_escena_sin_guion_no_tiene_proyecto():
    assert ctl._resolve_project_of_escena(None, _db()) is None
    assert ctl._resolve_project_of_escena("e1", _db({Scene: Obj(id_guion=None)})) is None
    assert ctl._resolve_project_of_escena("e1", _db({Scene: None})) is None


@pytest.mark.parametrize("accion", [
    lambda db: ctl.update_item_full("x", _item_nuevo(), db),
    lambda db: ctl.update_item("x", DesgloseItemUpdateSchema(), db),
    lambda db: ctl.delete_item("x", db),
])
def test_modificar_item_inexistente(accion):
    assert accion(_db({DesgloseItem: None}))["message"] == "Item de desglose no encontrado"


def test_borrar_item_avisa_cuantas_segmentaciones_se_fueron_con_el():
    item = _item()
    db = _db({DesgloseItem: item, DesgloseItemDetalle: [_detalle(), _detalle(id_detalle="d2")]})

    resp = ctl.delete_item("i1", db)

    assert db.deleted == [item]
    assert "2 fila(s)" in resp["message"]


def test_borrar_item_sin_segmentaciones_no_menciona_filas():
    resp = ctl.delete_item("i1", _db({DesgloseItem: _item(), DesgloseItemDetalle: []}))

    assert resp["message"] == "Item de desglose eliminado"


# ---------- segmentación por departamento ----------
def test_ver_la_segmentacion_de_otro_departamento_esta_prohibido():
    db = _db({DesgloseItem: _item(id_departamento=OTRO_DEPTO)})

    assert ctl.get_detalle_by_item("i1", db, YO)["error"] == "FORBIDDEN_DEPARTMENT"


def test_ver_la_segmentacion_de_mi_departamento():
    db = _db({DesgloseItem: _item(), DesgloseItemDetalle: [_detalle()]})

    resp = ctl.get_detalle_by_item("i1", db, YO)

    assert [d["etiqueta"] for d in resp["data"]] == ["Roja"]


def test_ver_segmentacion_de_item_inexistente():
    assert ctl.get_detalle_by_item("x", _db({DesgloseItem: None}), YO)["success"] is False


def test_crear_segmentacion_en_mi_departamento_guarda_el_editor():
    db = _db({DesgloseItem: _item()})

    resp = ctl.create_detalle("i1", DesgloseDetalleSchema(etiqueta="Roja"), db, YO)

    assert resp["data"]["id_user_editor"] == "u1"
    assert resp["data"]["estado"] == "pendiente"


def test_crear_segmentacion_en_otro_departamento_esta_prohibido():
    db = _db({DesgloseItem: _item(id_departamento=OTRO_DEPTO)})

    resp = ctl.create_detalle("i1", DesgloseDetalleSchema(etiqueta="Roja"), db, YO)

    assert resp["error"] == "FORBIDDEN_DEPARTMENT"
    assert db.added == []


def test_crear_segmentacion_de_item_inexistente():
    assert ctl.create_detalle("x", DesgloseDetalleSchema(etiqueta="a"), _db({DesgloseItem: None}), YO)["success"] is False


def test_actualizar_segmentacion_completa_y_parcial():
    detalle = _detalle()
    db = _db({DesgloseItemDetalle: detalle, DesgloseItem: _item()})

    ctl.update_detalle_full("d1", DesgloseDetalleSchema(etiqueta="Azul", estado="en_progreso", prioridad="alta"), db, YO)
    assert (detalle.etiqueta, detalle.estado, detalle.prioridad) == ("Azul", "en_progreso", "alta")

    ctl.update_detalle("d1", DesgloseDetalleUpdateSchema(estado="completado"), db, YO)
    assert (detalle.etiqueta, detalle.estado) == ("Azul", "completado")
    assert detalle.id_user_editor == "u1"


@pytest.mark.parametrize("accion", [
    lambda db: ctl.update_detalle_full("d1", DesgloseDetalleSchema(etiqueta="x"), db, YO),
    lambda db: ctl.update_detalle("d1", DesgloseDetalleUpdateSchema(estado="completado"), db, YO),
    lambda db: ctl.delete_detalle("d1", db, YO),
])
def test_modificar_segmentacion_de_otro_departamento_esta_prohibido(accion):
    detalle = _detalle(etiqueta="Original")
    db = _db({DesgloseItemDetalle: detalle, DesgloseItem: _item(id_departamento=OTRO_DEPTO)})

    assert accion(db)["error"] == "FORBIDDEN_DEPARTMENT"
    assert detalle.etiqueta == "Original"
    assert db.deleted == []


@pytest.mark.parametrize("accion", [
    lambda db: ctl.update_detalle_full("x", DesgloseDetalleSchema(etiqueta="x"), db, YO),
    lambda db: ctl.update_detalle("x", DesgloseDetalleUpdateSchema(), db, YO),
    lambda db: ctl.delete_detalle("x", db, YO),
])
def test_modificar_segmentacion_inexistente(accion):
    assert accion(_db({DesgloseItemDetalle: None}))["message"] == "Segmentación no encontrada"


def test_borrar_segmentacion_de_mi_departamento():
    detalle = _detalle()
    db = _db({DesgloseItemDetalle: detalle, DesgloseItem: _item()})

    resp = ctl.delete_detalle("d1", db, YO)

    assert resp["success"] is True
    assert db.deleted == [detalle]


# ---------- pendientes ----------
def test_pendientes_exige_departamento_asignado():
    db = FakeSession({User: _usuario(depto=None)})

    assert ctl.get_pendientes_mi_departamento("p1", db, YO)["message"] == "Tu usuario no tiene un departamento asignado"


def test_pendientes_salen_ordenados_por_prioridad_y_con_datos_del_item():
    pendientes = [
        _detalle(id_detalle="baja", prioridad="baja"),
        _detalle(id_detalle="sin", prioridad=None),
        _detalle(id_detalle="alta", prioridad="alta"),
        _detalle(id_detalle="media", prioridad="media"),
    ]
    db = _db({DesgloseItemDetalle: pendientes, DesgloseItem: _item()})

    resp = ctl.get_pendientes_mi_departamento("p1", db, YO)

    assert [d["id_detalle"] for d in resp["data"]] == ["alta", "media", "baja", "sin"]
    assert resp["data"][0]["categoria"] == "Props"
    assert resp["data"][0]["id_escena"] == "e1"
