"""Semana 7 (cobertura backend) — reglas del controlador de proyectos.

La regla central: un proyecto suspendido exige una causal y la causal no puede
existir en ningún otro estado (la BD también lo exige con un CHECK). Se prueba
en crear, actualizar completo y actualizar parcial. Sin BD: FakeSession.
"""
import pytest

from app.controllers import project_controller as ctl
from app.models.project_model import Project
from app.schemas.project_schema import ProjectSchema, ProjectUpdateSchema
from tests.fakes import FakeSession, Obj

CLIENTE = "22222222-2222-2222-2222-222222222222"


class Fila(Obj):
    def __getattr__(self, nombre):
        return None


def _proyecto(**attrs):
    base = dict(
        id_project="p1", project_name="Piloto", formato_de_produccion="Serie", genero="Drama",
        id_client=CLIENTE, estado="en_rodaje", causal_suspension=None,
    )
    base.update(attrs)
    return Fila(**base)


def _datos(**cambios):
    base = dict(project_name="Piloto", formato_de_produccion="Serie", genero="Drama", id_client=CLIENTE)
    base.update(cambios)
    return ProjectSchema(**base)


# ---------- la regla estado / causal ----------
@pytest.mark.parametrize("estado, causal, esperado", [
    ("suspendido", "temporal", ("suspendido", "temporal", None)),
    ("en_rodaje", None, ("en_rodaje", None, None)),
    ("preliminar", None, ("preliminar", None, None)),
])
def test_estado_y_causal_validos(estado, causal, esperado):
    assert ctl._normalizar_estado(estado, causal) == esperado


def test_suspendido_sin_causal_se_rechaza():
    estado, causal, error = ctl._normalizar_estado("suspendido", None)

    assert (estado, causal) == (None, None)
    assert "requiere una causal" in error


@pytest.mark.parametrize("estado", ["preliminar", "en_rodaje", "finalizado"])
def test_causal_en_un_estado_que_no_es_suspendido_se_rechaza(estado):
    _, _, error = ctl._normalizar_estado(estado, "temporal")

    assert error == "La causal solo aplica cuando el proyecto está suspendido"


# ---------- lectura ----------
def test_listar_proyectos_del_usuario_y_del_cliente():
    db = FakeSession({Project: [_proyecto(), _proyecto(id_project="p2")]})

    assert [p["id_project"] for p in ctl.get_projects("u1", db)["data"]] == ["p1", "p2"]
    assert len(ctl.get_projects_by_client(CLIENTE, db)["data"]) == 2


def test_get_proyecto_encontrado_y_no_encontrado():
    assert ctl.get_project("p1", FakeSession({Project: _proyecto()}))["data"]["estado"] == "en_rodaje"
    assert ctl.get_project("x", FakeSession({Project: None}))["message"] == "Proyecto no encontrado"


# ---------- crear ----------
def test_crear_proyecto_sin_estado_queda_preliminar():
    db = FakeSession({Project: None})

    resp = ctl.create_project(_datos(), db, CLIENTE)

    assert resp["success"] is True and db.commits == 1
    assert db.added[0].estado == "preliminar"
    assert resp["data"]["id_client"] == CLIENTE


def test_crear_proyecto_toma_el_cliente_del_actor_y_no_el_del_cuerpo():
    db = FakeSession({Project: None})

    ctl.create_project(_datos(id_client="otro-cliente"), db, CLIENTE)

    assert db.added[0].id_client == CLIENTE


def test_crear_proyecto_con_id_ya_existente_se_rechaza():
    db = FakeSession({Project: _proyecto()})

    resp = ctl.create_project(_datos(id_project="  p1  "), db, CLIENTE)

    assert resp["error"] == "DUPLICATE_PROJECT"
    assert db.added == []


def test_crear_proyecto_con_id_propio_lo_respeta():
    db = FakeSession({Project: None})

    ctl.create_project(_datos(id_project="mi-id"), db, CLIENTE)

    assert db.added[0].id_project == "mi-id"


def test_crear_proyecto_suspendido_sin_causal_se_rechaza():
    db = FakeSession({Project: None})

    resp = ctl.create_project(_datos(estado="suspendido"), db, CLIENTE)

    assert resp["error"] == "INVALID_PROJECT_STATE"
    assert db.added == []


def test_crear_y_vincular_hace_administrador_al_creador():
    db = FakeSession({Project: None})

    resp = ctl.create_project_and_link(_datos(), "u1", db, CLIENTE)

    vinculo = db.added[-1]
    assert (vinculo.id_user, vinculo.id_rol) == ("u1", 1001)
    assert resp["data"]["id_user"] == "u1"


def test_crear_y_vincular_no_vincula_si_la_creacion_falla():
    db = FakeSession({Project: _proyecto()})

    resp = ctl.create_project_and_link(_datos(id_project="p1"), "u1", db, CLIENTE)

    assert resp["success"] is False
    assert db.added == []


# ---------- actualizar completo ----------
def test_actualizar_completo_sin_estado_conserva_el_estado_actual():
    proyecto = _proyecto(estado="en_rodaje")

    ctl.update_project_full("p1", _datos(project_name="Nuevo"), FakeSession({Project: proyecto}))

    assert (proyecto.project_name, proyecto.estado) == ("Nuevo", "en_rodaje")


def test_actualizar_completo_a_suspendido_guarda_la_causal():
    proyecto = _proyecto()

    ctl.update_project_full("p1", _datos(estado="suspendido", causal_suspension="temporal"), FakeSession({Project: proyecto}))

    assert (proyecto.estado, proyecto.causal_suspension) == ("suspendido", "temporal")


def test_actualizar_completo_suspendido_sin_causal_se_rechaza_sin_confirmar():
    db = FakeSession({Project: _proyecto()})

    resp = ctl.update_project_full("p1", _datos(estado="suspendido"), db)

    assert resp["error"] == "INVALID_PROJECT_STATE"
    assert db.commits == 0


# ---------- actualizar parcial ----------
def test_actualizar_parcial_no_permite_cambiar_el_cliente():
    proyecto = _proyecto()

    ctl.update_project("p1", ProjectUpdateSchema(id_client="otro", genero="Comedia"), FakeSession({Project: proyecto}))

    assert (proyecto.id_client, proyecto.genero) == (CLIENTE, "Comedia")


def test_reactivar_un_proyecto_suspendido_limpia_la_causal():
    proyecto = _proyecto(estado="suspendido", causal_suspension="temporal")

    resp = ctl.update_project("p1", ProjectUpdateSchema(estado="en_rodaje"), FakeSession({Project: proyecto}))

    assert resp["success"] is True
    assert (proyecto.estado, proyecto.causal_suspension) == ("en_rodaje", None)


def test_cambiar_solo_la_causal_de_un_proyecto_suspendido():
    proyecto = _proyecto(estado="suspendido", causal_suspension="temporal")

    ctl.update_project("p1", ProjectUpdateSchema(causal_suspension="indefinido"), FakeSession({Project: proyecto}))

    assert (proyecto.estado, proyecto.causal_suspension) == ("suspendido", "indefinido")


def test_poner_causal_a_un_proyecto_que_no_esta_suspendido_se_rechaza():
    proyecto = _proyecto(estado="en_rodaje")
    db = FakeSession({Project: proyecto})

    resp = ctl.update_project("p1", ProjectUpdateSchema(causal_suspension="temporal"), db)

    assert resp["error"] == "INVALID_PROJECT_STATE"
    assert proyecto.causal_suspension is None and db.commits == 0


def test_suspender_sin_causal_se_rechaza():
    resp = ctl.update_project("p1", ProjectUpdateSchema(estado="suspendido"), FakeSession({Project: _proyecto()}))

    assert resp["error"] == "INVALID_PROJECT_STATE"


# ---------- inexistente y borrar ----------
@pytest.mark.parametrize("accion", [
    lambda db: ctl.update_project_full("x", _datos(), db),
    lambda db: ctl.update_project("x", ProjectUpdateSchema(), db),
    lambda db: ctl.delete_project("x", db),
])
def test_modificar_proyecto_inexistente(accion):
    assert accion(FakeSession({Project: None}))["message"] == "Proyecto no encontrado"


def test_borrar_proyecto():
    proyecto = _proyecto()
    db = FakeSession({Project: proyecto})

    assert ctl.delete_project("p1", db)["success"] is True
    assert db.deleted == [proyecto]
