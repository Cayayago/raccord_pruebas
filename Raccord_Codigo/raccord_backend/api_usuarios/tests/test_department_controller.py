"""Semana 7 (cobertura backend) — controlador de departamentos.

Regla con consecuencias: un departamento con personas asignadas NO se puede
eliminar (dejaría a esas personas sin área). Sin BD: FakeSession.
"""
import pytest

from app.controllers import department_controller as ctl
from app.models.department_model import Department
from app.models.user_model import User
from app.schemas.department_schema import DepartmentSchema, DepartmentUpdateSchema
from tests.fakes import FakeSession, Obj


def _depto(**attrs):
    base = dict(id_departamento="d1", nombre="Arte", ubicacion="Set")
    base.update(attrs)
    return Obj(**base)


def test_listar_departamentos():
    db = FakeSession({Department: [_depto(), _depto(id_departamento="d2", nombre="Sonido")]})

    resp = ctl.get_departments(db)

    assert [d["nombre"] for d in resp["data"]] == ["Arte", "Sonido"]


def test_get_departamento_encontrado_y_no_encontrado():
    assert ctl.get_department("d1", FakeSession({Department: _depto()}))["data"]["ubicacion"] == "Set"
    assert ctl.get_department("x", FakeSession({Department: None}))["message"] == "Departamento no encontrado"


def test_crear_departamento():
    db = FakeSession()

    resp = ctl.create_department(DepartmentSchema(nombre="Arte", ubicacion="Set"), db)

    assert db.commits == 1 and len(db.added) == 1
    assert resp["data"]["nombre"] == "Arte"


def test_actualizar_completo_reemplaza_nombre_y_ubicacion():
    depto = _depto()

    ctl.update_department_full("d1", DepartmentSchema(nombre="Vestuario", ubicacion="Bodega"), FakeSession({Department: depto}))

    assert (depto.nombre, depto.ubicacion) == ("Vestuario", "Bodega")


def test_actualizar_parcial_solo_cambia_lo_enviado():
    depto = _depto()

    ctl.update_department("d1", DepartmentUpdateSchema(ubicacion="Bodega"), FakeSession({Department: depto}))

    assert (depto.nombre, depto.ubicacion) == ("Arte", "Bodega")


@pytest.mark.parametrize("accion", [
    lambda db: ctl.update_department_full("x", DepartmentSchema(nombre="A", ubicacion="B"), db),
    lambda db: ctl.update_department("x", DepartmentUpdateSchema(), db),
    lambda db: ctl.delete_department("x", db),
])
def test_modificar_departamento_inexistente(accion):
    assert accion(FakeSession({Department: None}))["message"] == "Departamento no encontrado"


def test_no_se_elimina_un_departamento_con_usuarios_asignados():
    db = FakeSession({Department: _depto(), User: [Obj(id_user="u1"), Obj(id_user="u2")]})

    resp = ctl.delete_department("d1", db)

    assert resp["error"] == "DEPARTMENT_IN_USE"
    assert "2 usuario(s)" in resp["message"]
    assert db.deleted == [] and db.commits == 0


def test_se_elimina_un_departamento_sin_usuarios():
    depto = _depto()
    db = FakeSession({Department: depto, User: []})

    resp = ctl.delete_department("d1", db)

    assert resp["success"] is True
    assert db.deleted == [depto]
