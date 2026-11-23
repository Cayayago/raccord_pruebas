"""Semana 6 (cobertura) — reglas del controlador de actores.

Sin BD ni MinIO: la sesión es un FakeSession y las funciones de
almacenamiento se reemplazan por espías. Se prueban las reglas que importan:
qué archivos se aceptan como foto, qué se borra del almacenamiento y qué se
responde cuando el actor no existe.
"""
import asyncio
import io

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers

from app.controllers import actor_controller as ctl
from app.models.actor_model import Actor
from app.schemas.actor_schema import ActorSchema, ActorUpdateSchema
from tests.fakes import FakeSession, Obj

PROYECTO = "11111111-1111-1111-1111-111111111111"


class ActorFalso(Obj):
    """Fila de actor: cualquier columna no indicada vale None."""

    def __getattr__(self, nombre):
        return None


def _actor(**attrs):
    base = dict(id_actor="a1", nombre="Ana", apellido="Ruiz", id_project=PROYECTO)
    base.update(attrs)
    return ActorFalso(**base)


def _db(actor):
    return FakeSession({Actor: actor})


def _archivo(contenido=b"x", tipo="image/png", nombre="foto.png"):
    return UploadFile(file=io.BytesIO(contenido), filename=nombre, headers=Headers({"content-type": tipo}))


@pytest.fixture()
def almacenamiento(monkeypatch):
    llamadas = {"subidos": [], "borrados": [], "descarga": b"IMG"}

    monkeypatch.setattr(ctl, "upload_file", lambda bucket, key, data, tipo: llamadas["subidos"].append(key))
    monkeypatch.setattr(ctl, "delete_file", lambda bucket, key: llamadas["borrados"].append(key))

    def descargar(bucket, key):
        if isinstance(llamadas["descarga"], Exception):
            raise llamadas["descarga"]
        return llamadas["descarga"]

    monkeypatch.setattr(ctl, "download_file", descargar)
    return llamadas


# ---------- lectura ----------
def test_listar_actores_serializa_cada_fila():
    resp = ctl.get_actors(PROYECTO, FakeSession({Actor: [_actor(), _actor(id_actor="a2", nombre="Luis")]}))

    assert [a["id_actor"] for a in resp["data"]] == ["a1", "a2"]
    assert resp["data"][0]["fecha_de_nacimiento"] is None


def test_get_actor_devuelve_la_fecha_como_texto():
    from datetime import date

    resp = ctl.get_actor("a1", _db(_actor(fecha_de_nacimiento=date(1990, 5, 17))))

    assert resp["success"] is True
    assert resp["data"]["fecha_de_nacimiento"] == "1990-05-17"


def test_get_actor_que_no_existe():
    resp = ctl.get_actor("x", _db(None))

    assert (resp["success"], resp["message"]) == (False, "Actor no encontrado")


def test_actores_de_un_personaje():
    resp = ctl.get_actors_by_character("per-1", _db([_actor()]))

    assert resp["message"] == "Actores asignados a este personaje"
    assert len(resp["data"]) == 1


# ---------- escritura ----------
def test_crear_actor_lo_agrega_y_confirma():
    db = FakeSession()
    datos = ActorSchema(nombre="Ana", apellido="Ruiz", id_project=PROYECTO, categoria_cast="Principal")

    resp = ctl.create_actor(datos, db)

    assert db.commits == 1 and len(db.added) == 1
    assert resp["data"]["categoria_cast"] == "Principal"
    assert resp["data"]["id_project"] == PROYECTO


def test_actualizar_actor_completo_reemplaza_los_campos_pero_no_el_proyecto():
    actor = _actor(apellido="Viejo")
    datos = ActorSchema(nombre="Ana", apellido="Nuevo", id_project="22222222-2222-2222-2222-222222222222")

    ctl.update_actor_full("a1", datos, _db(actor))

    assert actor.apellido == "Nuevo"
    assert actor.id_project == PROYECTO


def test_actualizar_actor_parcial_solo_cambia_lo_enviado():
    actor = _actor(nombre="Ana", telefono="300")

    ctl.update_actor("a1", ActorUpdateSchema(telefono="311"), _db(actor))

    assert (actor.nombre, actor.telefono) == ("Ana", "311")


@pytest.mark.parametrize(
    "accion",
    [
        lambda db: ctl.update_actor_full("x", ActorSchema(nombre="A", apellido="B", id_project=PROYECTO), db),
        lambda db: ctl.update_actor("x", ActorUpdateSchema(), db),
        lambda db: ctl.delete_actor("x", db),
    ],
)
def test_modificar_actor_inexistente_responde_no_encontrado(accion, almacenamiento):
    assert accion(_db(None))["message"] == "Actor no encontrado"


def test_borrar_actor_tambien_borra_sus_dos_fotos_del_almacenamiento(almacenamiento):
    actor = _actor(foto_personaje_key="actors/a1_p.png", foto_normal_key="actors/a1_n.png")
    db = _db(actor)

    resp = ctl.delete_actor("a1", db)

    assert resp["success"] is True
    assert db.deleted == [actor]
    assert almacenamiento["borrados"] == ["actors/a1_p.png", "actors/a1_n.png"]


# ---------- fotos: subir ----------
def _subir(actor, archivo, columna="foto_normal_key"):
    return asyncio.run(ctl._upload_actor_photo("a1", archivo, _db(actor), columna, "normal"))


def test_subir_foto_de_actor_inexistente(almacenamiento):
    assert _subir(None, _archivo())["error"] == "ACTOR_NOT_FOUND"


def test_subir_foto_con_tipo_no_permitido_se_rechaza_sin_guardar(almacenamiento):
    resp = _subir(_actor(), _archivo(tipo="application/pdf", nombre="a.pdf"))

    assert resp["error"] == "INVALID_FILE_TYPE"
    assert almacenamiento["subidos"] == []


def test_subir_foto_vacia_se_rechaza(almacenamiento):
    assert _subir(_actor(), _archivo(contenido=b""))["error"] == "EMPTY_FILE"


def test_subir_foto_en_el_limite_se_acepta_y_un_byte_mas_se_rechaza(almacenamiento):
    limite = ctl.MAX_PHOTO_SIZE_BYTES

    assert _subir(_actor(), _archivo(contenido=b"x" * limite))["success"] is True
    assert _subir(_actor(), _archivo(contenido=b"x" * (limite + 1)))["error"] == "FILE_TOO_LARGE"


def test_subir_foto_guarda_la_llave_y_borra_la_anterior(almacenamiento):
    actor = _actor(foto_normal_key="actors/a1_foto_normal_key_vieja.png")

    resp = _subir(actor, _archivo(nombre="nueva.png"))

    assert resp["success"] is True
    assert actor.foto_normal_key == "actors/a1_foto_normal_key_nueva.png"
    assert almacenamiento["borrados"] == ["actors/a1_foto_normal_key_vieja.png"]


def test_subir_la_misma_foto_no_borra_lo_que_acaba_de_guardar(almacenamiento):
    actor = _actor(foto_normal_key="actors/a1_foto_normal_key_igual.png")

    _subir(actor, _archivo(nombre="igual.png"))

    assert almacenamiento["borrados"] == []


@pytest.mark.parametrize("subir, columna", [
    (ctl.upload_actor_foto_personaje, "foto_personaje_key"),
    (ctl.upload_actor_foto_normal, "foto_normal_key"),
])
def test_cada_endpoint_de_subida_usa_su_columna(subir, columna, almacenamiento):
    actor = _actor()

    asyncio.run(subir("a1", _archivo(), _db(actor)))

    assert getattr(actor, columna) is not None


# ---------- fotos: descargar ----------
def test_descargar_foto_devuelve_los_bytes(almacenamiento):
    resp = ctl.get_actor_foto_normal("a1", _db(_actor(foto_normal_key="k")))

    assert resp.body == b"IMG"


@pytest.mark.parametrize("actor", [None, _actor()])
def test_descargar_foto_que_no_existe_da_404(actor, almacenamiento):
    with pytest.raises(HTTPException) as error:
        ctl.get_actor_foto_personaje("a1", _db(actor))

    assert error.value.status_code == 404


def test_descargar_foto_con_el_almacenamiento_caido_da_404(almacenamiento):
    almacenamiento["descarga"] = RuntimeError("minio caído")

    with pytest.raises(HTTPException) as error:
        ctl.get_actor_foto_normal("a1", _db(_actor(foto_normal_key="k")))

    assert error.value.status_code == 404
