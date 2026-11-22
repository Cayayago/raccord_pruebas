"""
Semana 4 — Ángulo BD: endpoints cuya respuesta depende de lo guardado (Javier).

Pruebas de API con TestClient sobre la app REAL. La BD es un FakeSession
(fixture `api` en conftest.py): cada test decide qué "hay guardado" con
`api.db.results[Modelo] = ...` y luego verifica la respuesta HTTP y lo que el
endpoint le pidió a la BD (`api.db.deleted`, `api.db.commits`).

Cubre:
- Dependientes: no se borra un personaje con actores ni un día de rodaje con
  escenas; sin dependientes sí se borra.
- Inexistentes: 404 en JSON cuando el registro no existe.
- Listados que dependen de lo guardado: el día de rodaje trae sus escenas.
- Búsquedas y paginación de fotos: página, tamaño máximo, fechas inválidas.
- Papelera: borrar manda a la papelera (no borra la fila), restaurar solo lo
  que está en la papelera, el borrado definitivo sí elimina la fila.

Limitación (a propósito, ver fakes.py): el fake IGNORA los filtros; que el
filtro SQL exacto funcione es tema de las pruebas de integración (semana 6).
"""
from datetime import datetime

from app.models.actor_model import Actor
from app.models.character_model import Character
from app.models.gallery_photo_model import GalleryPhoto
from app.models.module_access_model import UserProjectModuleAccess
from app.models.scene_character_model import SceneCharacter
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.shooting_day_model import ShootingDay
from app.models.user_project_model import UserProject
from app.utils.permissions import ADMINISTRADOR, DIRECTOR, ONSET, USUARIO
from app.utils.security import create_access_token
from tests.fakes import Obj

PROYECTO = "11111111-1111-1111-1111-111111111111"


def _auth(id_rol=USUARIO):
    token = create_access_token({"id_user": "user-1", "mail": "ana@raccord.co", "id_rol": id_rol})
    return {"Authorization": f"Bearer {token}"}


def _miembro(id_rol):
    """Fila de user_projects: la persona pertenece al proyecto con ese rol."""
    return Obj(id_rol=id_rol, estado="activo")


def _es_json(response):
    return response.headers["content-type"].startswith("application/json")


def _personaje(id_personaje="per-1"):
    return Obj(id_personaje=id_personaje, nombre="ELENA", edad=30, codigo_personaje="P001", id_project=PROYECTO)


def _dia(id_rodaje="rod-1"):
    return Obj(
        id_rodaje=id_rodaje, version="1", semana_grabacion=1, dia_rodaje=2, hora_inicio=None, hora_fin=None,
        location="Bogotá", notas=None, activo=True, id_project=PROYECTO,
    )


def _escena(id_escena="esc-1", numero="1"):
    return Obj(
        id_escena=id_escena, id_guion="guion-1", numero_de_escena=numero, encabezado="INT. CASA - DÍA",
        descripcion=None, modo_vista="INT", momento_dia="dia", ciudad="Bogotá", pagina=1, dia_dramatico=1,
        id_rodaje="rod-1",
    )


def _foto(id_foto="f-1", eliminada=False):
    return Obj(
        id_foto=id_foto, id_escena="esc-1", tipo_foto="Prueba", personaje_codigo="P001", descripcion="chaqueta",
        notas_continuidad=None, archivo_nombre="foto.jpg", archivo_tamano=1024, archivo_key=f"fotos/{id_foto}.jpg",
        fecha_subida=datetime(2026, 11, 1, 10, 0), eliminada=eliminada,
        fecha_eliminacion=datetime(2026, 11, 2) if eliminada else None, eliminada_por=None,
    )


def _dueno_de_la_foto(api, id_rol, foto):
    """La foto, su escena y su guion existen; la persona es miembro con ese rol."""
    api.db.results.update({
        GalleryPhoto: foto,
        Scene: _escena(),
        Script: Obj(id_project=PROYECTO),
        UserProject: _miembro(id_rol),
    })


# ---------- Dependientes: no se borra lo que otros registros necesitan ----------

def test_delete_character_with_actors_is_blocked_and_nothing_is_deleted(api):
    # Arrange: el personaje existe y tiene 2 actores asignados
    api.db.results.update({
        Character: _personaje(),
        UserProject: _miembro(DIRECTOR),
        Actor: [Obj(), Obj()],
    })

    # Act
    response = api.client.delete("/characters/per-1", headers=_auth(DIRECTOR))

    # Assert: código, Content-Type, cuerpo y efecto en la BD
    assert response.status_code == 200
    assert _es_json(response)
    body = response.json()
    assert body["success"] is False
    assert body["error"] == "CHARACTER_HAS_ACTORS"
    assert "2 actor(es)" in body["message"]
    assert api.db.deleted == []
    assert api.db.commits == 0


def test_delete_character_without_actors_deletes_it_and_reports_scenes_affected(api):
    # Arrange: sin actores, pero aparece en el reparto de 3 escenas
    personaje = _personaje()
    api.db.results.update({
        Character: personaje,
        UserProject: _miembro(DIRECTOR),
        Actor: [],
        SceneCharacter: [Obj(), Obj(), Obj()],
    })

    response = api.client.delete("/characters/per-1", headers=_auth(DIRECTOR))

    body = response.json()
    assert response.status_code == 200
    assert body["success"] is True
    assert "3 escena(s)" in body["message"]
    assert api.db.deleted == [personaje]
    assert api.db.commits == 1


def test_delete_shooting_day_with_scheduled_scenes_is_blocked(api):
    # Arrange: el día tiene 2 escenas agendadas
    api.db.results.update({
        ShootingDay: _dia(),
        UserProject: _miembro(DIRECTOR),
        Scene: [_escena("esc-1"), _escena("esc-2", "2")],
    })

    response = api.client.delete("/shooting-days/rod-1", headers=_auth(DIRECTOR))

    body = response.json()
    assert _es_json(response)
    assert body["success"] is False
    assert body["error"] == "SHOOTING_DAY_IN_USE"
    assert "2 escena(s)" in body["message"]
    assert api.db.deleted == []


def test_delete_shooting_day_without_scenes_deletes_it(api):
    dia = _dia()
    api.db.results.update({ShootingDay: dia, UserProject: _miembro(DIRECTOR), Scene: []})

    response = api.client.delete("/shooting-days/rod-1", headers=_auth(DIRECTOR))

    assert response.json()["success"] is True
    assert api.db.deleted == [dia]


# ---------- Lo que la BD no soporta se rechaza antes de llegar a ella ----------
# HALLAZGO: personajes.nombre es varchar(45) y codigo_personaje varchar(30),
# pero CharacterSchema no limitaba la longitud: un nombre de 46 caracteres
# pasaba la validación, PostgreSQL lo rechazaba al guardar (value too long)
# y la persona recibía un 500 genérico en vez de un 422 que diga qué campo falla.

def _nuevo_personaje(**cambios):
    datos = {"nombre": "ELENA", "edad": 30, "codigo_personaje": "P001", "id_project": PROYECTO}
    datos.update(cambios)
    return datos


def test_create_character_with_a_name_longer_than_the_column_responds_422(api):
    api.db.results[UserProject] = _miembro(DIRECTOR)

    response = api.client.post("/characters", json=_nuevo_personaje(nombre="X" * 46), headers=_auth(DIRECTOR))

    assert response.status_code == 422
    assert _es_json(response)
    assert response.json()["detail"][0]["loc"] == ["body", "nombre"]
    assert api.db.added == []


def test_create_character_with_a_code_longer_than_the_column_responds_422(api):
    api.db.results[UserProject] = _miembro(DIRECTOR)

    response = api.client.post("/characters", json=_nuevo_personaje(codigo_personaje="P" * 31), headers=_auth(DIRECTOR))

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"] == ["body", "codigo_personaje"]


def test_create_character_with_values_exactly_at_the_column_limits_is_accepted(api):
    # Valores límite: 45 y 30 caracteres caben justo en la columna
    api.db.results[UserProject] = _miembro(DIRECTOR)

    response = api.client.post(
        "/characters", json=_nuevo_personaje(nombre="X" * 45, codigo_personaje="P" * 30), headers=_auth(DIRECTOR)
    )

    assert response.status_code == 200
    assert response.json()["success"] is True
    assert len(api.db.added) == 1


def test_character_schema_limits_match_the_database_columns():
    # Si alguien cambia el tamaño de la columna, el schema debe cambiar con ella
    from app.schemas.character_schema import CODIGO_MAX, NOMBRE_MAX

    columnas = Character.__table__.c
    assert columnas.nombre.type.length == NOMBRE_MAX
    assert columnas.codigo_personaje.type.length == CODIGO_MAX


def test_patch_character_with_a_name_longer_than_the_column_responds_422(api):
    api.db.results.update({Character: _personaje(), UserProject: _miembro(DIRECTOR)})

    response = api.client.patch("/characters/per-1", json={"nombre": "X" * 46}, headers=_auth(DIRECTOR))

    assert response.status_code == 422
    assert api.db.commits == 0


# ---------- Inexistentes y relaciones ----------

def test_delete_missing_character_responds_404_json(api):
    # Arrange: el registro no existe en la BD
    api.db.results[Character] = None

    response = api.client.delete("/characters/no-existe", headers=_auth(DIRECTOR))

    assert response.status_code == 404
    assert _es_json(response)
    assert response.json() == {"detail": "Personaje no encontrado"}


def test_shooting_day_detail_embeds_the_scenes_scheduled_that_day(api):
    # Arrange: la respuesta depende de las escenas guardadas para ese día
    api.db.results.update({
        ShootingDay: _dia(),
        UserProject: _miembro(USUARIO),
        Scene: [_escena("esc-1", "1"), _escena("esc-2", "2")],
    })

    response = api.client.get("/shooting-days/rod-1", headers=_auth())

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["id_rodaje"] == "rod-1"
    assert [e["numero_de_escena"] for e in data["escenas"]] == ["1", "2"]


def test_shooting_day_without_scenes_returns_an_empty_list_not_null(api):
    api.db.results.update({ShootingDay: _dia(), UserProject: _miembro(USUARIO), Scene: []})

    response = api.client.get("/shooting-days/rod-1", headers=_auth())

    assert response.json()["data"]["escenas"] == []


# ---------- Búsquedas, filtros y paginación ----------

def _busqueda(api, n_fotos, id_rol=USUARIO):
    api.db.results.update({
        UserProject: _miembro(id_rol),
        UserProjectModuleAccess: None,
        GalleryPhoto: [(_foto(f"f-{i}"), _escena()) for i in range(n_fotos)],
    })


def test_photo_search_returns_the_requested_page_with_totals(api):
    # Arrange: 5 fotos guardadas, páginas de 2
    _busqueda(api, 5)

    # Act: segunda página
    response = api.client.get(
        f"/fotos/project/{PROYECTO}/buscar", params={"page": 2, "page_size": 2}, headers=_auth()
    )

    # Assert: items de esa página y totales (5 fotos / 2 por página = 3 páginas)
    assert response.status_code == 200
    assert _es_json(response)
    data = response.json()["data"]
    assert [f["id_foto"] for f in data["items"]] == ["f-2", "f-3"]
    assert (data["total"], data["page"], data["page_size"], data["total_pages"]) == (5, 2, 2, 3)


def test_photo_search_in_a_project_without_photos_returns_an_empty_page(api):
    _busqueda(api, 0)

    response = api.client.get(f"/fotos/project/{PROYECTO}/buscar", headers=_auth())

    data = response.json()["data"]
    assert data["items"] == []
    assert data["total"] == 0 and data["total_pages"] == 0


def test_photo_search_caps_the_page_size_at_200(api):
    _busqueda(api, 3)

    response = api.client.get(f"/fotos/project/{PROYECTO}/buscar", params={"page_size": 5000}, headers=_auth())

    assert response.json()["data"]["page_size"] == 200


def test_photo_search_treats_page_zero_as_page_one(api):
    _busqueda(api, 3)

    response = api.client.get(f"/fotos/project/{PROYECTO}/buscar", params={"page": 0}, headers=_auth())

    data = response.json()["data"]
    assert data["page"] == 1
    assert len(data["items"]) == 3


def test_photo_search_with_a_malformed_date_responds_with_the_error_envelope(api):
    _busqueda(api, 3)

    response = api.client.get(f"/fotos/project/{PROYECTO}/buscar", params={"desde": "ayer"}, headers=_auth())

    body = response.json()
    assert body["success"] is False
    assert body["error"] == "INVALID_DATE"


def test_photo_search_with_a_non_numeric_page_responds_422_without_echoing_the_value(api):
    _busqueda(api, 3)

    response = api.client.get(f"/fotos/project/{PROYECTO}/buscar", params={"page": "dos"}, headers=_auth())

    assert response.status_code == 422
    assert "dos" not in response.text


# ---------- Papelera: soft-delete, restaurar y borrado definitivo ----------

def test_deleting_a_photo_moves_it_to_the_recycle_bin_without_deleting_the_row(api):
    # Arrange: Onset puede mandar fotos a la papelera
    foto = _foto()
    _dueno_de_la_foto(api, ONSET, foto)

    response = api.client.delete("/fotos/f-1", headers=_auth(ONSET))

    # Assert: la fila sigue ahí, marcada como eliminada y con quién lo hizo
    assert response.status_code == 200
    assert response.json()["data"]["eliminada"] is True
    assert foto.eliminada is True
    assert foto.fecha_eliminacion is not None
    assert foto.eliminada_por == "user-1"
    assert api.db.deleted == []


def test_restoring_a_photo_that_is_not_in_the_recycle_bin_is_rejected(api):
    foto = _foto(eliminada=False)
    _dueno_de_la_foto(api, DIRECTOR, foto)

    response = api.client.post("/fotos/f-1/restaurar", headers=_auth(DIRECTOR))

    body = response.json()
    assert body["success"] is False
    assert body["error"] == "NOT_DELETED"
    assert api.db.commits == 0


def test_restoring_a_photo_from_the_recycle_bin_brings_it_back(api):
    foto = _foto(eliminada=True)
    _dueno_de_la_foto(api, DIRECTOR, foto)

    response = api.client.post("/fotos/f-1/restaurar", headers=_auth(DIRECTOR))

    assert response.json()["success"] is True
    assert foto.eliminada is False
    assert foto.fecha_eliminacion is None
    assert api.db.commits == 1


def test_recycle_bin_is_not_visible_for_the_read_only_role(api):
    api.db.results[UserProject] = _miembro(USUARIO)

    response = api.client.get(f"/fotos/papelera/{PROYECTO}", headers=_auth())

    assert response.status_code == 403
    assert response.json()["detail"] == "No tienes permisos para realizar esta acción"


def test_director_sees_only_what_is_in_the_recycle_bin(api):
    api.db.results.update({
        UserProject: _miembro(DIRECTOR),
        UserProjectModuleAccess: None,
        GalleryPhoto: [(_foto("f-9", eliminada=True), _escena())],
    })

    response = api.client.get(f"/fotos/papelera/{PROYECTO}", headers=_auth(DIRECTOR))

    data = response.json()["data"]
    assert [f["id_foto"] for f in data] == ["f-9"]
    assert data[0]["eliminada"] is True


def test_permanent_delete_removes_the_file_and_the_row(api, monkeypatch):
    # Arrange: el binario vive en MinIO; el test registra qué se pidió borrar
    borrados = []
    monkeypatch.setattr(
        "app.controllers.gallery_photo_controller.delete_file", lambda bucket, key: borrados.append((bucket, key))
    )
    foto = _foto(eliminada=True)
    _dueno_de_la_foto(api, DIRECTOR, foto)

    response = api.client.delete("/fotos/f-1/definitivo", headers=_auth(DIRECTOR))

    assert response.json()["success"] is True
    assert borrados == [("imagenes", "fotos/f-1.jpg")]
    assert api.db.deleted == [foto]


def test_administrator_can_view_but_not_manage_the_recycle_bin(api):
    # El Administrador ve la papelera pero no restaura ni elimina definitivamente
    foto = _foto(eliminada=True)
    _dueno_de_la_foto(api, ADMINISTRADOR, foto)

    response = api.client.post("/fotos/f-1/restaurar", headers=_auth(ADMINISTRADOR))

    assert response.status_code == 403
    assert foto.eliminada is True
