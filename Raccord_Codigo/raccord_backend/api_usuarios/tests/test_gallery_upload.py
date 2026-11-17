"""
Capa API — Subida de fotos de continuidad
(app/controllers/gallery_photo_controller.py).

Reglas: solo JPEG/PNG/WEBP, no vacías, máximo 15 MB, y la escena debe
existir. MinIO se reemplaza por un doble: estas pruebas no suben nada.
"""
import asyncio

import pytest

from app.controllers import gallery_photo_controller as ctrl
from app.models.gallery_photo_model import GalleryPhoto
from app.models.scene_model import Scene
from tests.fakes import FakeSession, Obj

MB = 1024 * 1024


class FakeUpload:
    def __init__(self, contenido=b"\xff\xd8foto", content_type="image/jpeg", filename="foto.jpg"):
        self._contenido = contenido
        self.content_type = content_type
        self.filename = filename

    async def read(self):
        return self._contenido


@pytest.fixture
def minio(monkeypatch):
    subidos = []
    monkeypatch.setattr(ctrl, "upload_file", lambda bucket, key, data, ctype: subidos.append((bucket, key, len(data))))
    return subidos


def _subir(db, archivo, tipo_foto="Prueba"):
    return asyncio.run(ctrl.upload_photo("esc-1", tipo_foto, "P001", "desc", "notas", archivo, db))


def test_upload_photo_saves_metadata_and_uploads_binary(minio):
    # Arrange
    db = FakeSession({Scene: Obj(id_escena="esc-1")})

    # Act
    resp = _subir(db, FakeUpload())

    # Assert
    assert resp["success"] is True
    foto = db.added[0]
    assert foto.archivo_key == f"esc-1/{foto.id_foto}_foto.jpg"
    assert foto.archivo_tamano == len(b"\xff\xd8foto")
    assert minio == [("imagenes", foto.archivo_key, foto.archivo_tamano)]


@pytest.mark.parametrize("content_type", ["image/jpeg", "image/png", "image/webp"])
def test_upload_photo_accepts_allowed_image_types(minio, content_type):
    resp = _subir(FakeSession({Scene: Obj(id_escena="esc-1")}), FakeUpload(content_type=content_type))

    assert resp["success"] is True


@pytest.mark.parametrize("content_type", ["application/pdf", "image/gif", "image/heic"])
def test_upload_photo_rejects_other_file_types(minio, content_type):
    resp = _subir(FakeSession({Scene: Obj(id_escena="esc-1")}), FakeUpload(content_type=content_type))

    assert resp["error"] == "INVALID_FILE_TYPE"
    assert minio == []


@pytest.mark.parametrize("tamano, error", [(15 * MB, None), (15 * MB + 1, "FILE_TOO_LARGE")])
def test_upload_photo_size_limit_is_15_mb(minio, tamano, error):
    # Valores límite: exactamente 15 MB pasa, un byte más no
    resp = _subir(FakeSession({Scene: Obj(id_escena="esc-1")}), FakeUpload(contenido=b"x" * tamano))

    assert resp["error"] == error


def test_upload_photo_rejects_empty_file(minio):
    resp = _subir(FakeSession({Scene: Obj(id_escena="esc-1")}), FakeUpload(contenido=b""))

    assert resp["error"] == "EMPTY_FILE"


def test_upload_photo_fails_when_scene_does_not_exist(minio):
    resp = _subir(FakeSession(), FakeUpload())

    assert resp["error"] == "SCENE_NOT_FOUND"
    assert minio == []


def test_upload_photo_uses_default_name_and_type_when_missing(minio):
    db = FakeSession({Scene: Obj(id_escena="esc-1")})

    _subir(db, FakeUpload(filename=None), tipo_foto="")

    assert db.added[0].archivo_nombre == "foto.jpg"
    assert db.added[0].tipo_foto == "Set"


def test_get_photos_by_scene_hides_nothing_when_scene_missing():
    assert ctrl.get_photos_by_scene("x", FakeSession())["message"] == "Escena no encontrada"


def test_delete_photo_moves_it_to_recycle_bin_without_erasing_it():
    # Arrange
    foto = Obj(id_foto="f-1", id_escena="esc-1", tipo_foto="Prueba", personaje_codigo=None, descripcion=None,
               notas_continuidad=None, archivo_nombre="a.jpg", archivo_tamano=1, fecha_subida=None,
               eliminada=False, fecha_eliminacion=None, eliminada_por=None)
    db = FakeSession({GalleryPhoto: foto})

    # Act
    resp = ctrl.delete_photo("f-1", db, {"id_user": "onset-1"})

    # Assert
    assert resp["data"]["eliminada"] is True
    assert foto.eliminada_por == "onset-1"
    assert db.deleted == []  # soft-delete: la fila sigue existiendo


def test_restore_photo_only_works_for_photos_in_recycle_bin():
    foto = Obj(id_foto="f-1", eliminada=False)

    resp = ctrl.restore_photo("f-1", FakeSession({GalleryPhoto: foto}))

    assert resp["error"] == "NOT_DELETED"
