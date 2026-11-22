"""
Semana 4 — Ángulo E2E: seguridad y contrato de errores del API (Deiver).

Pruebas de API con TestClient sobre la app REAL (rutas, dependencias de
autenticación y permisos, manejadores de errores). La BD es un
FakeSession (fixture `api` en conftest.py): ningún test toca PostgreSQL.

Cubre:
- Endpoints protegidos: 401 (sin token, token falso, vencido o cerrado),
  403 (proyecto ajeno, rol sin permiso, módulo bloqueado) y autorizado.
- Contrato de errores: JSON mal formado, tipos incorrectos, errores de
  BD y errores inesperados, siempre en JSON y sin información interna.
"""
from datetime import datetime, timedelta

from jose import jwt
from sqlalchemy.exc import IntegrityError

from app.models.character_model import Character
from app.models.gallery_photo_model import GalleryPhoto
from app.models.module_access_model import UserProjectModuleAccess
from app.models.revoked_token_model import RevokedToken
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.user_project_model import UserProject
from app.utils.permissions import ADMINISTRADOR, USUARIO
from app.utils.security import ALGORITHM, SECRET_KEY, create_access_token
from tests.fakes import Obj

PROYECTO = "11111111-1111-1111-1111-111111111111"
SEÑALES_DE_FUGA = ("Traceback", "psycopg2", "INSERT INTO", "SELECT ", "[SQL:", "sqlalchemy")


def _auth(id_rol=USUARIO, **extra):
    token = create_access_token({"id_user": "user-1", "mail": "ana@raccord.co", "id_rol": id_rol, **extra})
    return {"Authorization": f"Bearer {token}"}


def _miembro(id_rol, estado="activo"):
    """Fila de user_projects: la persona pertenece al proyecto con ese rol."""
    return Obj(id_rol=id_rol, estado=estado)


def _es_json(response):
    return response.headers["content-type"].startswith("application/json")


def _sin_fugas(response):
    return not any(señal in response.text for señal in SEÑALES_DE_FUGA)


# ---------- 401: sin sesión válida ----------

def test_protected_endpoint_without_token_responds_401_json(api):
    # Act
    response = api.client.get("/projects")

    # Assert: código, Content-Type y cuerpo
    assert response.status_code == 401
    assert _es_json(response)
    assert response.json() == {"detail": "Not authenticated"}


def test_protected_endpoint_with_forged_token_responds_401(api):
    # Arrange: firmado con OTRA clave, como haría un atacante
    falso = jwt.encode({"id_user": "user-1", "id_rol": ADMINISTRADOR}, "otra-clave", algorithm=ALGORITHM)

    # Act
    response = api.client.get("/projects", headers={"Authorization": f"Bearer {falso}"})

    # Assert
    assert response.status_code == 401
    assert response.json()["detail"] == "Token inválido o expirado"


def test_protected_endpoint_with_expired_token_responds_401(api):
    vencido = jwt.encode(
        {"id_user": "user-1", "exp": datetime.utcnow() - timedelta(minutes=1)}, SECRET_KEY, algorithm=ALGORITHM
    )

    response = api.client.get("/projects", headers={"Authorization": f"Bearer {vencido}"})

    assert response.status_code == 401


def test_token_closed_with_logout_cannot_be_reused(api):
    # Arrange: el jti de este token está en tokens_revocados
    api.db.results[RevokedToken] = Obj(jti="cerrado")

    # Act
    response = api.client.get("/projects", headers=_auth())

    # Assert
    assert response.status_code == 401
    assert response.json()["detail"] == "Sesión cerrada. Vuelve a iniciar sesión."


# ---------- 403: con sesión, pero sin permiso ----------

def test_user_outside_project_gets_403(api):
    # Arrange: el usuario no tiene fila en user_projects para este proyecto
    api.db.results[UserProject] = None

    # Act
    response = api.client.get(f"/characters/project/{PROYECTO}", headers=_auth())

    # Assert
    assert response.status_code == 403
    assert response.json()["detail"] == "No perteneces a este proyecto"


def test_admin_role_in_token_does_not_grant_access_to_another_project(api):
    # El JWT dice Administrador, pero en ESTE proyecto la persona no está
    api.db.results[UserProject] = None

    response = api.client.get(f"/characters/project/{PROYECTO}", headers=_auth(id_rol=ADMINISTRADOR))

    assert response.status_code == 403


def test_member_suspended_in_project_gets_403(api):
    # Una persona suspendida en el proyecto queda como si no perteneciera
    api.db.results[UserProject] = _miembro(ADMINISTRADOR, estado="suspendido")

    response = api.client.get(f"/characters/project/{PROYECTO}", headers=_auth(id_rol=ADMINISTRADOR))

    assert response.status_code == 403
    assert response.json()["detail"] == "No perteneces a este proyecto"


def test_role_without_permission_cannot_upload_photos(api):
    # Arrange: la escena existe y es del proyecto; la persona es "Usuario" (solo lectura)
    api.db.results.update({
        Scene: Obj(id_escena="esc-1", id_guion="guion-1"),
        Script: Obj(id_project=PROYECTO),
        UserProject: _miembro(USUARIO),
    })

    # Act
    response = api.client.post(
        "/scenes/esc-1/fotos",
        headers=_auth(),
        files={"file": ("foto.jpg", b"\xff\xd8foto", "image/jpeg")},
        data={"tipo_foto": "Prueba"},
    )

    # Assert
    assert response.status_code == 403
    assert response.json()["detail"] == "No tienes permisos para realizar esta acción"


def test_administrator_cannot_delete_photos(api):
    # Regla de negocio: el Administrador VE fotos pero no las elimina
    api.db.results.update({
        GalleryPhoto: Obj(id_foto="f-1", id_escena="esc-1"),
        Scene: Obj(id_escena="esc-1", id_guion="guion-1"),
        Script: Obj(id_project=PROYECTO),
        UserProject: _miembro(ADMINISTRADOR),
    })

    response = api.client.delete("/fotos/f-1", headers=_auth(id_rol=ADMINISTRADOR))

    assert response.status_code == 403


def test_module_blocked_for_a_person_responds_403(api):
    # Arrange: miembro del proyecto, pero con "sin_acceso" en el módulo Guión
    api.db.results.update({
        UserProject: _miembro(USUARIO),
        UserProjectModuleAccess: Obj(nivel="sin_acceso"),
    })

    # Act
    response = api.client.get(f"/scripts/project/{PROYECTO}", headers=_auth())

    # Assert
    assert response.status_code == 403
    assert response.json()["detail"] == "No tienes acceso a este módulo en este proyecto"


def test_project_member_gets_200_with_standard_envelope(api):
    # Arrange: miembro con rol Usuario (solo lectura) y un personaje guardado
    api.db.results.update({
        UserProject: _miembro(USUARIO),
        UserProjectModuleAccess: None,
        Character: [Obj(id_personaje="per-1", nombre="ELENA", edad=30, codigo_personaje="P001", id_project=PROYECTO)],
    })

    # Act
    response = api.client.get(f"/characters/project/{PROYECTO}", headers=_auth())

    # Assert: código, Content-Type y cuerpo exacto del sobre
    assert response.status_code == 200
    assert _es_json(response)
    body = response.json()
    assert body["success"] is True
    assert body["error"] is None
    assert [p["nombre"] for p in body["data"]] == ["ELENA"]


# ---------- Contrato de errores ----------

def test_malformed_json_responds_400_with_json_detail(api):
    # HALLAZGO: antes respondía 422 con la lista cruda de Pydantic.
    response = api.client.post("/register", content='{"mail":', headers={"Content-Type": "application/json"})

    assert response.status_code == 400
    assert _es_json(response)
    assert response.json()["error"] == "MALFORMED_JSON"
    assert response.json()["detail"] == "El cuerpo de la petición no es un JSON válido"


def test_validation_error_does_not_echo_submitted_values(api):
    # HALLAZGO: el 422 devolvía en "input" lo enviado (aquí, la contraseña).
    secreto = ["MiClaveSecreta$2026"]

    response = api.client.post("/register", json={"mail": "no-es-correo", "contrasena": secreto})

    assert response.status_code == 422
    errores = response.json()["detail"]
    assert {"type", "loc", "msg"} == set(errores[0])
    assert "MiClaveSecreta" not in response.text


def test_register_duplicate_document_does_not_expose_sql(api):
    # HALLAZGO (comprobado contra PostgreSQL): con un NIT repetido la API
    # devolvía el error de psycopg2 con la restricción, el valor y el
    # INSERT completo de la tabla users.
    def commit_que_falla():
        raise IntegrityError(
            "INSERT INTO users (id_user, contrasena) VALUES (...)",
            {},
            Exception('duplicate key value violates unique constraint "users_id_identificacion_key"'),
        )

    api.db.flush = lambda: None
    api.db.commit = commit_que_falla
    datos = {
        "razon_social": "Cine SAS", "representante_legal": "Ana", "email_empresa": "info@cine.co",
        "document": "NIT", "id_document": "900123", "nombre": "Ana", "apellido": "Ruiz",
        "mail": "ana@cine.co", "msisdn": "300", "contrasena": "Clave$egura123",
    }

    response = api.client.post("/register", json=datos)

    body = response.json()
    assert body["success"] is False
    assert body["error"] == "DUPLICATE_DATA"
    assert _sin_fugas(response)
    assert "users_id_identificacion_key" not in response.text


def test_unexpected_error_responds_500_json_without_internal_details(api):
    # Arrange: la "BD" falla con un mensaje interno
    def query_que_explota(*args):
        raise RuntimeError("fallo interno: SELECT * FROM users WHERE contrasena = 'x'")

    api.db.query = query_que_explota

    # Act
    response = api.client.get("/projects", headers=_auth())

    # Assert
    assert response.status_code == 500
    assert _es_json(response)
    assert response.json()["error"] == "INTERNAL_SERVER_ERROR"
    assert _sin_fugas(response)


def test_unknown_route_responds_404_json(api):
    response = api.client.get("/no-existe")

    assert response.status_code == 404
    assert _es_json(response)
