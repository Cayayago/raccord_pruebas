"""
Capa API — Pantalla "Personalizar accesos"
(app/controllers/module_access_controller.py).

Regla de negocio: un Administrador/Director puede BAJAR el acceso de una
persona a un módulo, pero nunca subirlo por encima de lo que da su rol.
"""
import pytest
from pydantic import ValidationError

from app.controllers.module_access_controller import (
    delete_module_access,
    list_module_access,
    set_module_access,
)
from app.models.module_access_model import UserProjectModuleAccess
from app.models.user_project_model import UserProject
from app.schemas.module_access_schema import ModuleAccessSetSchema
from app.utils.module_access import MODULOS
from app.utils.permissions import JEFE_DEPARTAMENTO, ONSET
from tests.fakes import FakeSession, Obj


def _db(id_rol=ONSET, excepcion=None):
    return FakeSession({
        UserProject: Obj(id_rol=id_rol) if id_rol else None,
        UserProjectModuleAccess: excepcion,
    })


def test_set_module_access_creates_restriction_below_role_level():
    # Arrange: Onset tiene "comentar" en galería; se le baja a "ver"
    db = _db()

    # Act
    resp = set_module_access(db, "proj-1", "user-1", "galeria", "ver", "admin-1")

    # Assert
    assert resp["success"] is True
    assert db.added[0].nivel == "ver"
    assert db.added[0].id_actualizado_por == "admin-1"


def test_set_module_access_rejects_level_above_role():
    # Arrange: intentar darle "administrar" a un Onset
    db = _db()

    # Act
    resp = set_module_access(db, "proj-1", "user-1", "galeria", "administrar", "admin-1")

    # Assert
    assert resp["success"] is False
    assert "solo puede restringir" in resp["message"]
    assert db.added == []


def test_set_module_access_accepts_level_equal_to_role():
    # Valor límite: igual al del rol sí se permite (no amplía nada)
    resp = set_module_access(_db(), "proj-1", "user-1", "galeria", "comentar", "admin-1")

    assert resp["success"] is True


def test_set_module_access_updates_existing_exception_instead_of_duplicating():
    existente = Obj(nivel="ver", id_actualizado_por=None)
    db = _db(id_rol=JEFE_DEPARTAMENTO, excepcion=existente)

    set_module_access(db, "proj-1", "user-1", "galeria", "sin_acceso", "director-1")

    assert db.added == []
    assert existente.nivel == "sin_acceso"
    assert existente.id_actualizado_por == "director-1"


def test_set_module_access_rejects_unknown_module():
    resp = set_module_access(_db(), "proj-1", "user-1", "inventario", "ver", "a")

    assert resp == {"success": False, "message": "Módulo no reconocido", "data": None, "error": None}


def test_set_module_access_rejects_person_outside_project():
    resp = set_module_access(_db(id_rol=None), "proj-1", "user-1", "galeria", "ver", "a")

    assert resp["message"] == "Esa persona no pertenece a este proyecto"


def test_list_module_access_returns_all_modules_with_role_defaults():
    # Act
    resp = list_module_access(_db(excepcion=[]), "proj-1", "user-1")

    # Assert
    modulos = {m["modulo"]: m for m in resp["data"]["modulos"]}
    assert set(modulos) == set(MODULOS)
    assert modulos["galeria"]["nivel_efectivo"] == "comentar"
    assert modulos["roles"]["nivel_efectivo"] == "sin_acceso"
    assert not any(m["es_excepcion"] for m in modulos.values())


def test_list_module_access_fails_for_person_outside_project():
    assert list_module_access(_db(id_rol=None), "p", "u")["success"] is False


def test_delete_module_access_restores_role_level():
    fila = Obj(nivel="ver")
    db = _db(excepcion=fila)

    resp = delete_module_access(db, "proj-1", "user-1", "galeria")

    assert db.deleted == [fila]
    assert resp["data"]["nivel_efectivo"] == "comentar"


@pytest.mark.parametrize("modulo, excepcion", [("inventario", None), ("galeria", None)])
def test_delete_module_access_fails_without_exception_or_with_unknown_module(modulo, excepcion):
    resp = delete_module_access(_db(excepcion=excepcion), "p", "u", modulo)

    assert resp["success"] is False


@pytest.mark.parametrize("nivel", ["total", "VER", ""])
def test_module_access_schema_rejects_levels_outside_catalog(nivel):
    with pytest.raises(ValidationError):
        ModuleAccessSetSchema(nivel=nivel)
