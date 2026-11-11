"""Aislamiento por proyecto y por cliente (app/utils/project_scope.py).

Se prueban las reglas de autorización con un doble de sesión (sin BD).
"""
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.utils import project_scope as ps
from app.utils.permissions import ADMINISTRADOR, DIRECTOR, ONSET, USUARIO


class DBFalsa:
    """db.query(Modelo)...first() devuelve lo configurado por nombre de modelo."""

    def __init__(self, **por_modelo):
        self.por_modelo = por_modelo
        self._actual = None

    def query(self, modelo):
        self._actual = getattr(modelo, "__name__", str(modelo))
        return self

    def filter(self, *_):
        return self

    def first(self):
        return self.por_modelo.get(self._actual)


def vinculo(id_rol, estado="activo"):
    return SimpleNamespace(id_rol=id_rol, estado=estado)


USER = {"id_user": "u1", "mail": "a@x.com"}


# ------------------------------------------------ rol efectivo en el proyecto
def test_rol_efectivo_es_el_del_vinculo_activo():
    db = DBFalsa(UserProject=vinculo(ONSET))
    assert ps.get_role_in_project(db, "u1", "p1") == ONSET


def test_sin_vinculo_no_hay_rol():
    assert ps.get_role_in_project(DBFalsa(), "u1", "p1") is None


def test_vinculo_suspendido_se_trata_como_no_miembro():
    db = DBFalsa(UserProject=vinculo(ADMINISTRADOR, estado="suspendido"))
    assert ps.get_role_in_project(db, "u1", "p1") is None


@pytest.mark.parametrize("id_user, id_project", [(None, "p"), ("u", None), ("", "p"), ("u", "")])
def test_rol_efectivo_sin_ids_devuelve_none(id_user, id_project):
    db = DBFalsa(UserProject=vinculo(ADMINISTRADOR))
    assert ps.get_role_in_project(db, id_user, id_project) is None


# ------------------------------------------------ pertenencia y permiso
def test_membresia_devuelve_el_rol():
    db = DBFalsa(UserProject=vinculo(USUARIO))
    assert ps.check_project_membership(db, USER, "p1") == USUARIO


def test_no_miembro_recibe_403():
    with pytest.raises(HTTPException) as e:
        ps.check_project_membership(DBFalsa(), USER, "p1")
    assert e.value.status_code == 403


def test_permiso_concedido_si_el_rol_en_ese_proyecto_lo_tiene():
    db = DBFalsa(UserProject=vinculo(DIRECTOR))
    assert ps.check_project_permission(db, USER, "p1", "upload_scripts") == DIRECTOR


def test_permiso_denegado_a_rol_sin_el_permiso():
    db = DBFalsa(UserProject=vinculo(USUARIO))
    with pytest.raises(HTTPException) as e:
        ps.check_project_permission(db, USER, "p1", "upload_scripts")
    assert e.value.status_code == 403


def test_permiso_en_proyecto_ajeno_se_niega_aunque_sea_admin_en_otro():
    # El rol sale de user_projects del proyecto consultado, no del JWT.
    user_admin_en_jwt = {**USER, "id_rol": ADMINISTRADOR}
    with pytest.raises(HTTPException) as e:
        ps.check_project_permission(DBFalsa(), user_admin_en_jwt, "proyecto-ajeno", "full_management")
    assert e.value.status_code == 403


# ------------------------------------------------ aislamiento entre clientes
def test_mismo_cliente_pasa_y_devuelve_el_id():
    db = DBFalsa(User=SimpleNamespace(id_client="c1"))
    assert ps.require_same_client("c1", USER, db) == "c1"


def test_cliente_distinto_recibe_403():
    db = DBFalsa(User=SimpleNamespace(id_client="c1"))
    with pytest.raises(HTTPException) as e:
        ps.require_same_client("c2", USER, db)
    assert e.value.status_code == 403


def test_usuario_sin_cliente_asignado_recibe_403():
    db = DBFalsa(User=SimpleNamespace(id_client=None))
    with pytest.raises(HTTPException):
        ps.require_same_client("c1", USER, db)


def test_get_user_client_usuario_inexistente():
    assert ps.get_user_client(DBFalsa(), "u1") is None


# ------------------------------------------------ dependencias FastAPI
def _req(**path):
    return SimpleNamespace(path_params=path)


def test_require_project_member_agrega_rol_y_proyecto_al_usuario():
    dep = ps.require_project_member()
    db = DBFalsa(UserProject=vinculo(ONSET))
    out = dep(request=_req(id_project="p1"), db=db, current_user={**USER, "id_rol": ADMINISTRADOR})
    assert out["id_rol"] == ONSET          # sobrescribe el rol global del JWT
    assert out["id_project"] == "p1"


def test_require_project_member_sin_parametro_en_la_ruta_da_400():
    dep = ps.require_project_member()
    with pytest.raises(HTTPException) as e:
        dep(request=_req(), db=DBFalsa(), current_user=USER)
    assert e.value.status_code == 400


def test_require_project_permission_deniega_sin_permiso():
    dep = ps.require_project_permission("manage_projects")
    db = DBFalsa(UserProject=vinculo(ONSET))
    with pytest.raises(HTTPException) as e:
        dep(request=_req(id_project="p1"), db=db, current_user=USER)
    assert e.value.status_code == 403


def test_require_project_permission_sin_parametro_da_400():
    dep = ps.require_project_permission("manage_projects")
    with pytest.raises(HTTPException) as e:
        dep(request=_req(), db=DBFalsa(), current_user=USER)
    assert e.value.status_code == 400


class _Modelo:
    id = None


def test_registro_inexistente_da_404():
    dep = ps.require_record_project_permission(None, model=_Modelo, pk_column="id")
    with pytest.raises(HTTPException) as e:
        dep(request=_req(id="x"), db=DBFalsa(_Modelo=None), current_user=USER)
    assert e.value.status_code == 404


def test_registro_sin_proyecto_da_409():
    dep = ps.require_record_project_permission(None, model=_Modelo, pk_column="id")
    db = DBFalsa(_Modelo=SimpleNamespace(id_project=None))
    with pytest.raises(HTTPException) as e:
        dep(request=_req(id="x"), db=db, current_user=USER)
    assert e.value.status_code == 409


def test_registro_de_otro_proyecto_da_403():
    dep = ps.require_record_project_permission("create_characters", model=_Modelo, pk_column="id")
    db = DBFalsa(_Modelo=SimpleNamespace(id_project="p-ajeno"))  # sin vínculo en UserProject
    with pytest.raises(HTTPException) as e:
        dep(request=_req(id="x"), db=db, current_user=USER)
    assert e.value.status_code == 403


def test_registro_con_permiso_devuelve_usuario_con_proyecto_del_registro():
    dep = ps.require_record_project_permission("create_characters", model=_Modelo, pk_column="id")
    db = DBFalsa(_Modelo=SimpleNamespace(id_project="p1"), UserProject=vinculo(DIRECTOR))
    out = dep(request=_req(id="x"), db=db, current_user=USER)
    assert out["id_project"] == "p1" and out["id_rol"] == DIRECTOR


def test_registro_con_permission_none_solo_exige_membresia():
    dep = ps.require_record_project_permission(None, model=_Modelo, pk_column="id")
    db = DBFalsa(_Modelo=SimpleNamespace(id_project="p1"), UserProject=vinculo(USUARIO))
    assert dep(request=_req(id="x"), db=db, current_user=USER)["id_rol"] == USUARIO


def test_registro_usa_el_resolver_personalizado():
    dep = ps.require_record_project_permission(
        None, model=_Modelo, pk_column="id", resolve_project=lambda rec, db: "p-resuelto"
    )
    db = DBFalsa(_Modelo=SimpleNamespace(), UserProject=vinculo(USUARIO))
    assert dep(request=_req(id="x"), db=db, current_user=USER)["id_project"] == "p-resuelto"


# ------------------------------------------------ resolvers de cadena
def test_proyecto_de_escena_sube_por_el_guion():
    escena = SimpleNamespace(id_guion="g1")
    db = DBFalsa(Script=SimpleNamespace(id_project="p1"))
    assert ps.resolve_project_of_scene(escena, db) == "p1"


@pytest.mark.parametrize("escena", [None, SimpleNamespace(id_guion=None)])
def test_escena_sin_guion_no_tiene_proyecto(escena):
    assert ps.resolve_project_of_scene(escena, DBFalsa()) is None


def test_resolver_via_fk_de_escena():
    resolver = ps.resolve_project_via_scene_fk("id_escena")
    db = DBFalsa(Scene=SimpleNamespace(id_guion="g1"), Script=SimpleNamespace(id_project="p1"))
    assert resolver(SimpleNamespace(id_escena="e1"), db) == "p1"


def test_resolver_via_fk_sin_escena_devuelve_none():
    assert ps.resolve_project_via_scene_fk("id_escena")(SimpleNamespace(id_escena=None), DBFalsa()) is None


def test_resolver_de_detalle_de_desglose_sube_hasta_el_proyecto():
    db = DBFalsa(
        DesgloseItem=SimpleNamespace(id_escena="e1"),
        Scene=SimpleNamespace(id_guion="g1"),
        Script=SimpleNamespace(id_project="p1"),
    )
    assert ps.resolve_project_via_desglose_item(SimpleNamespace(id_desglose_item="i1"), db) == "p1"


@pytest.mark.parametrize(
    "detalle, db",
    [
        (None, DBFalsa()),
        (SimpleNamespace(id_desglose_item=None), DBFalsa()),
        (SimpleNamespace(id_desglose_item="i1"), DBFalsa()),  # item no existe
        (SimpleNamespace(id_desglose_item="i1"), DBFalsa(DesgloseItem=SimpleNamespace(id_escena=None))),
    ],
)
def test_resolver_de_detalle_con_cadena_rota_devuelve_none(detalle, db):
    assert ps.resolve_project_via_desglose_item(detalle, db) is None


def test_require_same_client_user_404_si_el_usuario_objetivo_no_existe():
    dep = ps.require_same_client_user()
    with pytest.raises(HTTPException) as e:
        dep(request=_req(id="x"), db=DBFalsa(), current_user=USER)
    assert e.value.status_code == 404


def test_require_same_client_user_403_si_es_de_otra_empresa():
    dep = ps.require_same_client_user()
    # DBFalsa devuelve el mismo User para ambas consultas: se separa con dos dobles.
    class Db2(DBFalsa):
        def __init__(self):
            super().__init__()
            self.n = 0

        def first(self):
            self.n += 1
            return SimpleNamespace(id_client="c-objetivo") if self.n == 1 else SimpleNamespace(id_client="c-propio")

    with pytest.raises(HTTPException) as e:
        dep(request=_req(id="x"), db=Db2(), current_user=USER)
    assert e.value.status_code == 403
