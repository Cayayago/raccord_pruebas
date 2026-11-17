"""Los modelos SQLAlchemy se declaran y sus relaciones se resuelven.

Detecta, sin BD, errores como una relationship() hacia una clase
inexistente o una ForeignKey a una tabla que no está declarada: fallos
que de otro modo solo explotan al primer request en producción.
"""
import importlib
import pkgutil

import pytest
from sqlalchemy.orm import configure_mappers

import app.models as modelos
from app.config.database import Base


def _importar_todos():
    for m in pkgutil.iter_modules(modelos.__path__):
        importlib.import_module(f"app.models.{m.name}")


def test_todos_los_modelos_configuran_sus_relaciones():
    _importar_todos()
    configure_mappers()  # lanza si alguna relationship es inconsistente


def test_toda_foreign_key_apunta_a_una_tabla_declarada():
    _importar_todos()
    tablas = set(Base.metadata.tables)
    for tabla in Base.metadata.tables.values():
        for fk in tabla.foreign_keys:
            assert fk.column.table.name in tablas, f"{tabla.name} -> {fk.target_fullname}"


def test_toda_tabla_tiene_llave_primaria():
    _importar_todos()
    sin_pk = [t.name for t in Base.metadata.tables.values() if not list(t.primary_key.columns)]
    assert sin_pk == []


@pytest.mark.parametrize(
    "tabla",
    ["users", "login_intentos", "login_bloqueos", "tokens_revocados", "user_project_module_access"],
)
def test_tablas_criticas_de_seguridad_estan_declaradas(tabla):
    _importar_todos()
    assert tabla in Base.metadata.tables
