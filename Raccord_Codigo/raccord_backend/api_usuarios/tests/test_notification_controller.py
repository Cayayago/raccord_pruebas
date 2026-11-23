"""Semana 7 (cobertura backend) — reglas del controlador de notificaciones.

Qué se valida: alcance y origen permitidos, departamentos que existen, tipo y
tamaño de la foto, que marcar como leída no duplique y que la foto no se sirva
si no existe. Sin BD ni MinIO: FakeSession y espías de almacenamiento.
"""
import asyncio
import io
from datetime import datetime

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers

from app.controllers import notification_controller as ctl
from app.models.department_model import Department
from app.models.notification_model import Notification, NotificationRead
from app.models.user_model import User
from tests.fakes import FakeSession, Obj

PROYECTO = "11111111-1111-1111-1111-111111111111"
AUTOR = "u1"


class Fila(Obj):
    def __getattr__(self, nombre):
        return None


def _notif(**attrs):
    base = dict(
        id_notificacion="n1", id_project=PROYECTO, id_user_autor=AUTOR, tipo_alcance="general",
        origen="manual", texto="Llamado 6am", foto_key=None, fecha_creacion=datetime(2026, 11, 20, 8, 0),
    )
    base.update(attrs)
    return Fila(**base)


def _usuario(depto=None):
    return Fila(id_user=AUTOR, nombre="Ana", apellido="Ruiz", id_departamento=depto)


def _archivo(contenido=b"x", tipo="image/png", nombre="foto.png"):
    return UploadFile(file=io.BytesIO(contenido), filename=nombre, headers=Headers({"content-type": tipo}))


@pytest.fixture()
def minio(monkeypatch):
    subidos = []
    monkeypatch.setattr(ctl, "upload_file", lambda bucket, key, data, tipo: subidos.append((key, tipo)))
    monkeypatch.setattr(ctl, "download_file", lambda bucket, key: b"IMG")
    return subidos


def _crear(db, **cambios):
    datos = dict(
        id_project=PROYECTO, id_user_autor=AUTOR, tipo_alcance="general", departamentos_csv=None,
        texto="Llamado 6am", origen="manual", file=None, db=db,
    )
    datos.update(cambios)
    return asyncio.run(ctl.create_notification(**datos))


# ---------- listar ----------
def test_listar_sin_departamento_serializa_autor_y_estado_de_lectura():
    db = FakeSession({User: _usuario(), Notification: [_notif()], NotificationRead: Fila()})

    resp = ctl.get_notifications_for_user(PROYECTO, {"id_user": AUTOR}, db)

    fila = resp["data"][0]
    assert fila["autor_nombre"] == "Ana Ruiz"
    assert fila["leida"] is True
    assert fila["tiene_foto"] is False
    assert fila["fecha_creacion"] == "2026-11-20T08:00:00"


def test_listar_con_departamento_incluye_las_especificas_y_sus_departamentos():
    depto = Fila(id_departamento="d1", nombre="Arte")
    db = FakeSession({
        User: _usuario(depto="d1"),
        Notification: [_notif(tipo_alcance="especifica", foto_key="k")],
        Department: [depto],
    })

    fila = ctl.get_notifications_for_user(PROYECTO, {"id_user": AUTOR}, db)["data"][0]

    assert fila["departamentos"] == [{"id_departamento": "d1", "nombre": "Arte"}]
    assert fila["tiene_foto"] is True
    assert fila["leida"] is False


@pytest.mark.parametrize("depto", [None, "d1"])
def test_contar_no_leidas(depto):
    db = FakeSession({User: _usuario(depto=depto), Notification: [_notif(), _notif(id_notificacion="n2")]})

    resp = ctl.get_unread_count(PROYECTO, {"id_user": AUTOR}, db)

    assert resp["data"] == {"no_leidas": 2}


def test_notificacion_sin_autor_no_rompe_la_serializacion():
    db = FakeSession({User: None, Notification: [_notif(id_user_autor=None)]})

    fila = ctl.get_notifications_for_user(PROYECTO, {"id_user": AUTOR}, db)["data"][0]

    assert fila["autor_nombre"] is None


# ---------- crear: validaciones ----------
@pytest.mark.parametrize("cambios, error", [
    ({"tipo_alcance": "todos"}, "INVALID_ALCANCE"),
    ({"origen": "correo"}, "INVALID_ORIGEN"),
    ({"texto": ""}, "EMPTY_TEXT"),
    ({"texto": "   "}, "EMPTY_TEXT"),
    ({"tipo_alcance": "especifica", "departamentos_csv": None}, "NO_DEPARTMENTS"),
    ({"tipo_alcance": "especifica", "departamentos_csv": " , "}, "NO_DEPARTMENTS"),
])
def test_crear_notificacion_invalida_se_rechaza_sin_guardar(cambios, error, minio):
    db = FakeSession()

    resp = _crear(db, **cambios)

    assert resp["error"] == error
    assert db.added == [] and db.commits == 0


def test_crear_especifica_con_departamento_inexistente_se_rechaza(minio):
    db = FakeSession({Department.id_departamento: [Fila(id_departamento="d1")]})

    resp = _crear(db, tipo_alcance="especifica", departamentos_csv="d1,d2")

    assert resp["error"] == "DEPARTMENT_NOT_FOUND"
    assert db.added == []


def test_crear_con_foto_de_tipo_no_permitido_se_rechaza(minio):
    resp = _crear(FakeSession(), file=_archivo(tipo="application/pdf", nombre="a.pdf"))

    assert resp["error"] == "INVALID_FILE_TYPE"
    assert minio == []


def test_foto_en_el_limite_se_acepta_y_un_byte_mas_se_rechaza(minio):
    limite = ctl.MAX_FILE_SIZE_BYTES

    assert _crear(FakeSession({User: _usuario()}), file=_archivo(contenido=b"x" * limite))["success"] is True
    assert _crear(FakeSession(), file=_archivo(contenido=b"x" * (limite + 1)))["error"] == "FILE_TOO_LARGE"


# ---------- crear: caminos felices ----------
def test_crear_general_sin_foto_marca_leida_al_autor(minio):
    db = FakeSession({User: _usuario()})

    resp = _crear(db, texto="  Llamado 6am  ")

    assert resp["success"] is True and db.commits == 1
    assert resp["data"]["texto"] == "Llamado 6am"
    assert resp["data"]["tiene_foto"] is False
    assert any(isinstance(o, NotificationRead) and o.id_user == AUTOR for o in db.added)
    assert minio == []


def test_crear_especifica_guarda_un_vinculo_por_departamento_sin_repetir(minio):
    db = FakeSession({User: _usuario(), Department.id_departamento: [Fila(), Fila()]})

    resp = _crear(db, tipo_alcance="especifica", departamentos_csv="d1, d2, d1")

    assert resp["success"] is True
    vinculos = [o for o in db.added if type(o).__name__ == "NotificationDepartamento"]
    assert sorted(v.id_departamento for v in vinculos) == ["d1", "d2"]


def test_crear_con_foto_la_sube_y_guarda_la_llave(minio):
    db = FakeSession({User: _usuario()})

    resp = _crear(db, file=_archivo(nombre="set.png"))

    assert resp["data"]["tiene_foto"] is True
    assert len(minio) == 1 and minio[0][0].endswith("_set.png") and minio[0][1] == "image/png"


def test_crear_con_archivo_vacio_se_publica_sin_foto(minio):
    resp = _crear(FakeSession({User: _usuario()}), file=_archivo(contenido=b""))

    assert resp["success"] is True
    assert resp["data"]["tiene_foto"] is False
    assert minio == []


# ---------- marcar como leída ----------
def test_marcar_leida_una_notificacion_inexistente():
    resp = ctl.mark_as_read("x", AUTOR, FakeSession({Notification: None}))

    assert resp["error"] == "NOTIFICATION_NOT_FOUND"


def test_marcar_leida_registra_la_lectura_una_sola_vez():
    db = FakeSession({Notification: _notif(), NotificationRead: None})
    ctl.mark_as_read("n1", AUTOR, db)
    assert len(db.added) == 1 and db.commits == 1

    ya = FakeSession({Notification: _notif(), NotificationRead: Fila()})
    assert ctl.mark_as_read("n1", AUTOR, ya)["success"] is True
    assert ya.added == [] and ya.commits == 0


# ---------- foto ----------
@pytest.mark.parametrize("notif", [None, _notif()])
def test_foto_de_notificacion_sin_foto_da_404(notif, minio):
    with pytest.raises(HTTPException) as error:
        ctl.get_notification_photo("n1", FakeSession({Notification: notif}))

    assert error.value.status_code == 404


def test_foto_se_sirve_con_su_tipo_y_nombre(minio):
    notif = _notif(foto_key="k", foto_tipo="image/png", foto_nombre="set.png")

    resp = ctl.get_notification_photo("n1", FakeSession({Notification: notif}))

    assert resp.body == b"IMG"
    assert resp.media_type == "image/png"
    assert 'filename="set.png"' in resp.headers["content-disposition"]


def test_foto_con_el_almacenamiento_caido_da_404(monkeypatch):
    def caido(bucket, key):
        raise RuntimeError("minio caído")

    monkeypatch.setattr(ctl, "download_file", caido)

    with pytest.raises(HTTPException) as error:
        ctl.get_notification_photo("n1", FakeSession({Notification: _notif(foto_key="k")}))

    assert error.value.status_code == 404
