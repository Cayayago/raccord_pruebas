"""Accesos por módulo (app/utils/module_access.py).

La excepción por persona SOLO puede restringir, nunca ampliar el rol.
La consulta a BD se sustituye por un doble (sin base de datos).
"""
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.utils import module_access as ma
from app.utils.permissions import ADMINISTRADOR, DIRECTOR, JEFE_DEPARTAMENTO, ONSET, USUARIO


class _DBFalsa:
    """Imita db.query(...).filter(...).first() devolviendo la excepción dada."""

    def __init__(self, override=None):
        self.override = override

    def query(self, *_):
        return self

    def filter(self, *_):
        return self

    def first(self):
        return self.override


def _override(nivel):
    return SimpleNamespace(nivel=nivel)


USER = {"id_user": "u1"}


def test_niveles_ordenados_de_menor_a_mayor():
    orden = sorted(ma.NIVEL_RANGO, key=ma.NIVEL_RANGO.get)
    assert orden == ["sin_acceso", "ver", "comentar", "editar", "administrar"]


@pytest.mark.parametrize("nivel, valido", [("ver", True), ("administrar", True), ("root", False), ("", False)])
def test_nivel_valido(nivel, valido):
    assert ma.nivel_valido(nivel) is valido


@pytest.mark.parametrize(
    "rol, modulo, esperado",
    [
        (ADMINISTRADOR, "guion", "administrar"),
        (DIRECTOR, "roles", "administrar"),
        (JEFE_DEPARTAMENTO, "desglose", "editar"),
        (JEFE_DEPARTAMENTO, "galeria", "administrar"),
        (ONSET, "escenas", "comentar"),
        (ONSET, "roles", "sin_acceso"),
        (USUARIO, "roles", "sin_acceso"),
        (USUARIO, "galeria", "ver"),
        (9999, "guion", "sin_acceso"),         # rol desconocido: deniega
        (None, "guion", "sin_acceso"),
        (ADMINISTRADOR, "modulo_x", "sin_acceso"),  # módulo desconocido: deniega
    ],
)
def test_nivel_por_defecto_del_rol(rol, modulo, esperado):
    assert ma.get_role_default_level(rol, modulo) == esperado


def test_todos_los_roles_cubren_los_nueve_modulos():
    for rol, niveles in ma.ROLE_MODULE_LEVELS.items():
        assert set(niveles) == set(ma.MODULOS), f"rol {rol}"


def test_sin_excepcion_rige_el_nivel_del_rol():
    nivel = ma.get_effective_module_level(_DBFalsa(None), "u", "p", "galeria", ONSET)
    assert nivel == "comentar"


def test_excepcion_mas_restrictiva_se_aplica():
    nivel = ma.get_effective_module_level(_DBFalsa(_override("sin_acceso")), "u", "p", "galeria", DIRECTOR)
    assert nivel == "sin_acceso"


def test_excepcion_nunca_amplia_el_rol():
    # Un Usuario ("ver") con excepción "administrar" sigue en "ver".
    nivel = ma.get_effective_module_level(_DBFalsa(_override("administrar")), "u", "p", "galeria", USUARIO)
    assert nivel == "ver"


def test_excepcion_igual_al_rol_no_cambia_nada():
    # Valor límite: mismo rango que el rol.
    nivel = ma.get_effective_module_level(_DBFalsa(_override("ver")), "u", "p", "galeria", USUARIO)
    assert nivel == "ver"


def test_excepcion_con_nivel_invalido_se_ignora():
    nivel = ma.get_effective_module_level(_DBFalsa(_override("superadmin")), "u", "p", "galeria", ONSET)
    assert nivel == "comentar"


def test_check_module_view_access_bloquea_sin_acceso():
    with pytest.raises(HTTPException) as e:
        ma.check_module_view_access(_DBFalsa(None), USER, "p", "roles", USUARIO)
    assert e.value.status_code == 403


def test_check_module_view_access_permite_con_nivel_ver():
    ma.check_module_view_access(_DBFalsa(None), USER, "p", "galeria", USUARIO)  # no lanza


def test_check_any_pasa_si_al_menos_un_modulo_es_accesible():
    # Usuario no ve "roles" pero sí "crew_list".
    ma.check_module_view_access_any(_DBFalsa(None), USER, "p", ["roles", "crew_list"], USUARIO)


def test_check_any_bloquea_solo_si_todos_son_sin_acceso():
    with pytest.raises(HTTPException) as e:
        ma.check_module_view_access_any(_DBFalsa(None), USER, "p", ["roles"], USUARIO)
    assert e.value.status_code == 403
