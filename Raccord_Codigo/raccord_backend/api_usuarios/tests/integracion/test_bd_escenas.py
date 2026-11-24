"""Semana 6 (capa BD, Deiver) — la tabla `escenas` contra PostgreSQL real.

Raccord no tiene una capa "repositorio": las consultas viven en
`app/controllers/scene_controller.py`. Aquí ese controlador hace de DAO y se
prueba contra la BD de pruebas:

- Cada función de consulta al menos una vez (crear, buscar, listar por
  proyecto / guion / día de rodaje / desglose, actualizar, borrar).
- Las consultas propias: el JOIN escenas -> guiones para filtrar por
  proyecto, los filtros por guion y día, y el ORDER BY.
- Cada restricción de la tabla documentada con un test: NOT NULL, longitud
  (varchar 45 / 20), rango de integer, llaves foráneas y ON DELETE CASCADE.

Limpieza: ROLLBACK (fixture `db_session` de conftest.py). Cada test crea sus
propios datos con valores únicos y no usa ids fijos. Sin DATABASE_URL se
saltan, así que el CI sin BD sigue en verde.
"""
import uuid

import pytest
from sqlalchemy import text

import app.main  # noqa: F401  registra todos los modelos (FK a plan_rodaje, desgloses...)
from sqlalchemy.exc import DataError, IntegrityError

from app.controllers import scene_controller as escenas
from app.schemas.scene_schema import SceneSchema


# ------------------------------------------------------------------
# Datos propios de cada test
# ------------------------------------------------------------------
def _proyecto(db):
    """Cliente + proyecto + guion + día de rodaje + desglose, todos nuevos."""
    sufijo = uuid.uuid4().hex[:8]
    ids = {k: uuid.uuid4() for k in ("cliente", "proyecto", "guion", "rodaje", "desglose")}
    db.execute(
        text(
            "insert into clients (id_cliente, document, id_document, razon_social, representante_legal, email) "
            "values (:cliente, 'NIT', :doc, 'Productora BD', 'Rep BD', :mail)"
        ),
        {"cliente": ids["cliente"], "doc": f"901{sufijo}", "mail": f"bd-{sufijo}@test.com"},
    )
    db.execute(
        text(
            "insert into projects (id_project, project_name, formato_de_produccion, genero, id_client) "
            "values (:proyecto, :nombre, 'Serie', 'Drama', :cliente)"
        ),
        {**ids, "nombre": f"Proyecto {sufijo}"},
    )
    db.execute(
        text(
            "insert into guiones (id_guion, numero_de_version, fecha_de_emision, estado, nombre, id_project) "
            "values (:guion, :version, '2026-11-01', 'Borrador', 'Guion BD', :proyecto)"
        ),
        {**ids, "version": f"v-{sufijo}"},
    )
    db.execute(
        text("insert into plan_rodaje (id_rodaje, version, id_project) values (:rodaje, 'v1', :proyecto)"),
        ids,
    )
    db.execute(
        text(
            "insert into desgloses (id_desglose, version, requerimientos, id_project) "
            "values (:desglose, 'v1', 'Utilería', :proyecto)"
        ),
        ids,
    )
    db.flush()
    return {k: str(v) for k, v in ids.items()}


def _escena(db, id_guion, numero="1", **campos):
    """Crea una escena con el controlador real y devuelve su id."""
    datos = {"numero_de_escena": numero, "encabezado": f"INT. CASA - DIA ({numero})", "id_guion": id_guion}
    datos.update(campos)
    respuesta = escenas.create_scene(SceneSchema(**datos), db)
    assert respuesta["success"] is True, respuesta
    return respuesta["data"]["id_escena"]


def _fila(db, id_escena):
    return db.execute(text("select * from escenas where id_escena = :i"), {"i": id_escena}).mappings().first()


def _insert_directo(db, **valores):
    """INSERT sin pasar por el schema: para ver qué hace la BD sola."""
    columnas = ", ".join(valores)
    marcadores = ", ".join(f":{c}" for c in valores)
    db.execute(text(f"insert into escenas ({columnas}) values ({marcadores})"), valores)
    db.flush()


# ------------------------------------------------------------------
# Crear y buscar (estado verificado EN LA BD, no en la respuesta)
# ------------------------------------------------------------------
def test_create_scene_saves_the_row_with_db_defaults(db_session):
    p = _proyecto(db_session)

    id_escena = _escena(db_session, p["guion"], numero="12A", momento_dia="noche", pagina=7)

    fila = _fila(db_session, id_escena)
    assert fila is not None
    assert str(fila["id_guion"]) == p["guion"]
    assert fila["numero_de_escena"] == "12A"
    assert fila["momento_dia"] == "noche" and fila["pagina"] == 7
    assert fila["estado"] == "Pendiente"          # default de la columna
    assert uuid.UUID(str(fila["id_escena"]))       # gen_random_uuid() de PostgreSQL


def test_get_scene_finds_the_created_scene_and_reports_missing_ones(db_session):
    p = _proyecto(db_session)
    id_escena = _escena(db_session, p["guion"], numero="3")

    encontrada = escenas.get_scene(id_escena, db_session)
    inexistente = escenas.get_scene(str(uuid.uuid4()), db_session)

    assert encontrada["data"]["numero_de_escena"] == "3"
    assert inexistente["success"] is False


# ------------------------------------------------------------------
# Consultas propias: JOIN, filtros y orden
# ------------------------------------------------------------------
def test_get_scenes_by_project_joins_through_the_script_and_ignores_other_projects(db_session):
    mio, ajeno = _proyecto(db_session), _proyecto(db_session)
    _escena(db_session, mio["guion"], numero="1")
    _escena(db_session, mio["guion"], numero="2")
    _escena(db_session, ajeno["guion"], numero="1")

    respuesta = escenas.get_scenes(mio["proyecto"], db_session)

    assert sorted(e["numero_de_escena"] for e in respuesta["data"]) == ["1", "2"]
    assert {str(e["id_guion"]) for e in respuesta["data"]} == {mio["guion"]}


def test_get_scenes_by_project_embeds_the_cast_from_the_link_table(db_session):
    p = _proyecto(db_session)
    con_reparto = _escena(db_session, p["guion"], numero="1")
    _escena(db_session, p["guion"], numero="2")
    id_personaje = uuid.uuid4()
    db_session.execute(
        text(
            "insert into personajes (id_personaje, nombre, edad, codigo_personaje, id_project) "
            "values (:i, 'Laura', 30, 'P-01', :p)"
        ),
        {"i": id_personaje, "p": p["proyecto"]},
    )
    db_session.execute(
        text("insert into escenas_personajes (id_escena, id_personaje) values (:e, :i)"),
        {"e": con_reparto, "i": id_personaje},
    )

    datos = {e["numero_de_escena"]: e for e in escenas.get_scenes(p["proyecto"], db_session)["data"]}

    assert [c["nombre"] for c in datos["1"]["cast"]] == ["Laura"]
    assert datos["2"]["cast"] == []


def test_scenes_by_shooting_day_and_breakdown_only_bring_the_assigned_ones(db_session):
    p = _proyecto(db_session)
    for numero in ["12", "4", "30", "7"]:
        _escena(db_session, p["guion"], numero=numero, id_rodaje=p["rodaje"])
    for numero in ["21", "5", "13", "8"]:
        _escena(db_session, p["guion"], numero=numero, id_desglose=p["desglose"])
    _escena(db_session, p["guion"], numero="99")  # sin día ni desglose

    del_dia = escenas.get_scenes_by_rodaje(p["rodaje"], db_session)["data"]
    del_desglose = escenas.get_scenes_by_desglose(p["desglose"], db_session)["data"]

    assert [e["numero_de_escena"] for e in del_dia] == ["4", "7", "12", "30"]
    assert [e["numero_de_escena"] for e in del_desglose] == ["5", "8", "13", "21"]


def test_scenes_by_project_also_come_in_script_order(db_session):
    # Agregado tras la mutación M1: quitar el orden en get_scenes se escapaba,
    # porque el test del JOIN compara con sorted().
    p = _proyecto(db_session)
    for numero in ["3", "11", "1B", "2", "1"]:
        _escena(db_session, p["guion"], numero=numero)

    respuesta = escenas.get_scenes(p["proyecto"], db_session)

    assert [e["numero_de_escena"] for e in respuesta["data"]] == ["1", "1B", "2", "3", "11"]


def test_scenes_by_script_come_in_script_order_not_in_uuid_order(db_session):
    # Hallazgo S6: se ordenaba por id_escena (UUID aleatorio). Con el
    # FakeSession el ORDER BY no se ejecuta, así que nunca se vio.
    p = _proyecto(db_session)
    for numero in ["10", "2", "10A", "1", "9"]:
        _escena(db_session, p["guion"], numero=numero)

    respuesta = escenas.get_scenes_by_script(p["guion"], db_session)

    assert [e["numero_de_escena"] for e in respuesta["data"]] == ["1", "2", "9", "10", "10A"]


# ------------------------------------------------------------------
# Actualizar y borrar
# ------------------------------------------------------------------
def test_patch_changes_only_the_sent_columns(db_session):
    from app.schemas.scene_schema import SceneUpdateSchema

    p = _proyecto(db_session)
    id_escena = _escena(db_session, p["guion"], numero="4", ciudad="Bogotá")

    escenas.update_scene(id_escena, SceneUpdateSchema(estado="Finalizada"), db_session)

    fila = _fila(db_session, id_escena)
    assert fila["estado"] == "Finalizada"
    assert fila["ciudad"] == "Bogotá" and fila["numero_de_escena"] == "4"


def test_moving_a_scene_to_another_projects_script_leaves_the_row_untouched(db_session):
    mio, ajeno = _proyecto(db_session), _proyecto(db_session)
    id_escena = _escena(db_session, mio["guion"], numero="5")
    cuerpo = SceneSchema(numero_de_escena="5", encabezado="EXT. CALLE", id_guion=ajeno["guion"])

    respuesta = escenas.update_scene_full(id_escena, cuerpo, db_session)

    assert respuesta["error"] == "CROSS_PROJECT_MOVE"
    assert str(_fila(db_session, id_escena)["id_guion"]) == mio["guion"]


def test_deleting_a_scene_cascades_to_its_cast_links_and_photos(db_session):
    p = _proyecto(db_session)
    id_escena = _escena(db_session, p["guion"], numero="6")
    id_personaje = uuid.uuid4()
    db_session.execute(
        text(
            "insert into personajes (id_personaje, nombre, edad, codigo_personaje, id_project) "
            "values (:i, 'Pedro', 40, 'P-02', :p)"
        ),
        {"i": id_personaje, "p": p["proyecto"]},
    )
    db_session.execute(
        text("insert into escenas_personajes (id_escena, id_personaje) values (:e, :i)"),
        {"e": id_escena, "i": id_personaje},
    )
    db_session.execute(
        text(
            "insert into fotos_continuidad (id_escena, archivo_nombre, archivo_key, archivo_tipo, archivo_tamano) "
            "values (:e, 'f.jpg', :k, 'image/jpeg', 10)"
        ),
        {"e": id_escena, "k": f"fotos/{uuid.uuid4()}.jpg"},
    )

    escenas.delete_scene(id_escena, db_session)

    contar = lambda tabla: db_session.execute(  # noqa: E731
        text(f"select count(*) from {tabla} where id_escena = :e"), {"e": id_escena}
    ).scalar()
    assert contar("escenas") == 0
    assert contar("escenas_personajes") == 0     # ON DELETE CASCADE
    assert contar("fotos_continuidad") == 0      # ON DELETE CASCADE
    # El personaje NO se borra: solo el vínculo.
    assert db_session.execute(
        text("select count(*) from personajes where id_personaje = :i"), {"i": id_personaje}
    ).scalar() == 1


def test_deleting_the_script_deletes_its_scenes(db_session):
    p = _proyecto(db_session)
    id_escena = _escena(db_session, p["guion"], numero="7")

    db_session.execute(text("delete from guiones where id_guion = :g"), {"g": p["guion"]})

    assert _fila(db_session, id_escena) is None


# ------------------------------------------------------------------
# Restricciones de la tabla (documentadas con la BD sola)
# ------------------------------------------------------------------
@pytest.mark.parametrize("columna", ["numero_de_escena", "encabezado"])
def test_not_null_columns_are_rejected_by_the_db(db_session, columna):
    p = _proyecto(db_session)
    valores = {"numero_de_escena": "1", "encabezado": "INT. CASA", "id_guion": p["guion"]}
    valores[columna] = None

    with pytest.raises(IntegrityError, match="not-null"):
        _insert_directo(db_session, **valores)


def test_scene_number_longer_than_45_chars_is_rejected_by_the_db(db_session):
    p = _proyecto(db_session)

    with pytest.raises(DataError, match="too long"):
        _insert_directo(db_session, numero_de_escena="x" * 46, encabezado="INT. CASA", id_guion=p["guion"])


def test_page_out_of_integer_range_is_rejected_by_the_db(db_session):
    p = _proyecto(db_session)

    with pytest.raises(DataError, match="out of range"):
        _insert_directo(
            db_session, numero_de_escena="1", encabezado="INT. CASA", id_guion=p["guion"], pagina=3_000_000_000
        )


def test_shooting_day_that_does_not_exist_violates_the_foreign_key(db_session):
    p = _proyecto(db_session)

    with pytest.raises(IntegrityError, match="escenas_id_rodaje_fkey"):
        _insert_directo(
            db_session, numero_de_escena="1", encabezado="INT. CASA", id_guion=p["guion"], id_rodaje=uuid.uuid4()
        )


# ------------------------------------------------------------------
# Hallazgo S6: la versión del guion era única en TODA la BD
# ------------------------------------------------------------------
def _guion(proyecto, version):
    from app.schemas.script_schema import ScriptSchema

    return ScriptSchema(
        numero_de_version=version, fecha_de_emision="2026-11-24", estado="Borrador",
        nombre="Guion", id_project=proyecto,
    )


def test_two_projects_can_each_have_a_script_with_the_same_version(db_session):
    # El código ya decía "la versión solo tiene que ser única DENTRO del
    # mismo proyecto", pero la tabla tenía UNIQUE(numero_de_version) global:
    # si otra productora ya tenía un "V2", crear el tuyo daba 500.
    from app.controllers.script_controller import create_script

    version = f"V2-{uuid.uuid4().hex[:6]}"
    a, b = _proyecto(db_session), _proyecto(db_session)

    primero = create_script(_guion(a["proyecto"], version), db_session)
    segundo = create_script(_guion(b["proyecto"], version), db_session)

    assert primero["success"] is True and segundo["success"] is True
    assert db_session.execute(
        text("select count(*) from guiones where numero_de_version = :v"), {"v": version}
    ).scalar() == 2


def test_the_same_version_twice_in_one_project_is_rejected_by_the_db(db_session):
    # La regla sigue existiendo, ahora por proyecto: UNIQUE(id_project, numero_de_version).
    p = _proyecto(db_session)
    version = db_session.execute(
        text("select numero_de_version from guiones where id_guion = :g"), {"g": p["guion"]}
    ).scalar()

    with pytest.raises(IntegrityError, match="guiones_proyecto_version_key"):
        db_session.execute(
            text(
                "insert into guiones (numero_de_version, fecha_de_emision, estado, nombre, id_project) "
                "values (:v, '2026-11-24', 'Borrador', 'Copia', :p)"
            ),
            {"v": version, "p": p["proyecto"]},
        )
        db_session.flush()


# ------------------------------------------------------------------
# Red de integración: lo que antes era 500 por el API
# ------------------------------------------------------------------
@pytest.fixture()
def api_escenas(db_session):
    """TestClient real con la sesión de PostgreSQL de prueba y un admin propio."""
    from fastapi.testclient import TestClient

    from app.config.database import get_db
    from app.main import app as aplicacion
    from app.utils import rate_limit
    from app.utils.security import create_access_token

    p = _proyecto(db_session)
    id_user, sufijo = uuid.uuid4(), uuid.uuid4().hex[:8]
    db_session.execute(
        text(
            "insert into users (id_user, nombre, apellido, identificacion, id_identificacion, mail, msisdn, "
            "fecha_de_nacimiento, estado, contrasena, id_client, id_rol) values (:u, 'Deiver', 'BD', 'CC', :ident, "
            ":mail, '3000000000', '1990-01-01', 'activo', 'x', :c, 1001)"
        ),
        {"u": id_user, "ident": f"cc-{sufijo}", "mail": f"bd-{sufijo}@test.com", "c": p["cliente"]},
    )
    db_session.execute(
        text("insert into user_projects (id, id_user, id_project, id_rol) values (:i, :u, :p, 1001)"),
        {"i": uuid.uuid4(), "u": id_user, "p": p["proyecto"]},
    )
    token = create_access_token({"id_user": str(id_user), "mail": "bd@test.com", "id_rol": 1001})
    rate_limit._attempts.clear()
    aplicacion.dependency_overrides[get_db] = lambda: db_session
    try:
        yield TestClient(aplicacion, raise_server_exceptions=False), {"Authorization": f"Bearer {token}"}, p
    finally:
        aplicacion.dependency_overrides.clear()


def _escenas_guardadas(db, id_guion):
    return db.execute(text("select count(*) from escenas where id_guion = :g"), {"g": id_guion}).scalar()


@pytest.mark.parametrize(
    "cambio",
    [
        {"numero_de_escena": "x" * 46},
        {"numero_de_escena": ""},
        {"pagina": 3_000_000_000},
        {"pagina": -1},
        {"id_rodaje": "abc"},
    ],
    ids=["numero-46", "numero-vacio", "pagina-desborda", "pagina-negativa", "rodaje-no-uuid"],
)
def test_post_scene_with_values_outside_the_table_limits_answers_422_and_saves_nothing(api_escenas, db_session, cambio):
    cliente, headers, p = api_escenas

    r = cliente.post("/scenes", json={"numero_de_escena": "1", "encabezado": "INT", "id_guion": p["guion"], **cambio},
                     headers=headers)

    assert r.status_code == 422
    assert _escenas_guardadas(db_session, p["guion"]) == 0


def test_post_scene_with_a_shooting_day_that_does_not_exist_is_not_a_500(api_escenas, db_session):
    cliente, headers, p = api_escenas

    r = cliente.post("/scenes", json={"numero_de_escena": "1", "encabezado": "INT", "id_guion": p["guion"],
                                      "id_rodaje": str(uuid.uuid4())}, headers=headers)

    assert r.status_code == 200
    assert r.json()["error"] == "INVALID_REFERENCE"
    assert _escenas_guardadas(db_session, p["guion"]) == 0
