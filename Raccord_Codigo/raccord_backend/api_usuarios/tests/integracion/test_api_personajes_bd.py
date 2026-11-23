"""Semana 6 (capa API) — POST /characters contra PostgreSQL real.

A diferencia de los tests unitarios (FakeSession), aquí la ruta, el permiso por
proyecto, el trigger que genera `id_personaje` y las restricciones de la BD
trabajan de verdad. Cada test arma sus propios datos (cliente, usuario,
proyecto, vínculo y token) dentro de la transacción de `db_session`, que se
deshace al terminar (ver conftest.py). Sin DATABASE_URL se saltan.
"""
import uuid

import pytest
from sqlalchemy import text

ROL_ADMIN = 1001
ROL_SOLO_LECTURA = 1005


def _sembrar(db, rol):
    """Crea cliente + usuario + proyecto + vínculo. Devuelve (id_user, id_project)."""
    sufijo = uuid.uuid4().hex[:8]
    id_client, id_user, id_project = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()
    db.execute(
        text(
            "insert into clients (id_cliente, document, id_document, razon_social, representante_legal, email) "
            "values (:c, 'NIT', :doc, 'Productora Test', 'Rep Test', :email)"
        ),
        {"c": id_client, "doc": f"900{sufijo}", "email": f"cli-{sufijo}@test.com"},
    )
    db.execute(
        text(
            "insert into users (id_user, nombre, apellido, identificacion, id_identificacion, mail, msisdn, "
            "fecha_de_nacimiento, estado, contrasena, id_client, id_rol) "
            "values (:u, 'Ana', 'Prueba', 'CC', :ident, :mail, '3000000000', '1990-01-01', 'activo', 'x', :c, :rol)"
        ),
        {"u": id_user, "ident": f"cc-{sufijo}", "mail": f"u-{sufijo}@test.com", "c": id_client, "rol": rol},
    )
    db.execute(
        text(
            "insert into projects (id_project, project_name, formato_de_produccion, genero, id_client) "
            "values (:p, 'Proyecto Test', 'Largometraje', 'Drama', :c)"
        ),
        {"p": id_project, "c": id_client},
    )
    db.execute(
        text("insert into user_projects (id, id_user, id_project, id_rol) values (:i, :u, :p, :rol)"),
        {"i": uuid.uuid4(), "u": id_user, "p": id_project, "rol": rol},
    )
    db.commit()
    return id_user, id_project


@pytest.fixture()
def api_bd(db_session):
    """TestClient de la app real cuya sesión es la de PostgreSQL de prueba."""
    from fastapi.testclient import TestClient

    from app.config.database import get_db
    from app.main import app
    from app.utils import rate_limit

    rate_limit._attempts.clear()
    app.dependency_overrides[get_db] = lambda: db_session
    try:
        yield TestClient(app, raise_server_exceptions=False)
    finally:
        app.dependency_overrides.clear()


def _headers(id_user, rol):
    from app.utils.security import create_access_token

    token = create_access_token({"id_user": str(id_user), "mail": "u@test.com", "id_rol": rol})
    return {"Authorization": f"Bearer {token}"}


def _cuerpo(id_project, **cambios):
    cuerpo = {"nombre": "Laura", "edad": 30, "codigo_personaje": "P-01", "id_project": str(id_project)}
    cuerpo.update(cambios)
    return cuerpo


def _contar(db, id_project):
    return db.execute(
        text("select count(*) from personajes where id_project = :p"), {"p": id_project}
    ).scalar()


def test_crear_personaje_lo_guarda_en_la_bd_con_id_generado_por_la_bd(api_bd, db_session):
    id_user, id_project = _sembrar(db_session, ROL_ADMIN)

    r = api_bd.post("/characters", json=_cuerpo(id_project), headers=_headers(id_user, ROL_ADMIN))

    assert r.status_code == 200, r.text
    id_personaje = r.json()["data"]["id_personaje"]
    assert str(uuid.UUID(id_personaje)) == id_personaje  # la BD lo generó como UUID válido
    fila = db_session.execute(
        text("select nombre, edad, codigo_personaje from personajes where id_personaje = :i"),
        {"i": id_personaje},
    ).one()
    assert tuple(fila) == ("Laura", 30, "P-01")


def test_usuario_de_solo_lectura_recibe_403_y_no_se_inserta_nada(api_bd, db_session):
    id_user, id_project = _sembrar(db_session, ROL_SOLO_LECTURA)

    r = api_bd.post("/characters", json=_cuerpo(id_project), headers=_headers(id_user, ROL_SOLO_LECTURA))

    assert r.status_code == 403
    assert _contar(db_session, id_project) == 0


def test_id_project_que_no_es_uuid_responde_4xx_y_no_500(api_bd, db_session):
    # Hallazgo candidato: PostgreSQL rechaza 'abc' como uuid (DataError) y, sin
    # una regla previa, el API lo deja salir como 500 en vez de un 4xx.
    id_user, _ = _sembrar(db_session, ROL_ADMIN)

    r = api_bd.post("/characters", json=_cuerpo("abc"), headers=_headers(id_user, ROL_ADMIN))

    assert 400 <= r.status_code < 500, r.text


def test_edad_fuera_del_rango_de_integer_responde_4xx_y_no_500(api_bd, db_session):
    # Hallazgo candidato: 3_000_000_000 pasa el esquema (int de Python) pero no
    # cabe en la columna integer de PostgreSQL; en MySQL/SQLite no fallaba igual.
    id_user, id_project = _sembrar(db_session, ROL_ADMIN)

    r = api_bd.post(
        "/characters", json=_cuerpo(id_project, edad=3_000_000_000), headers=_headers(id_user, ROL_ADMIN)
    )

    assert 400 <= r.status_code < 500, r.text
    assert _contar(db_session, id_project) == 0
