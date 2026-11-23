"""Configuración común de las pruebas unitarias (Semana 2).

Las pruebas unitarias NO tocan infraestructura (FIRST):
- Sin PostgreSQL: las variables DB_* solo permiten construir el engine de
  SQLAlchemy (create_engine es perezoso y no se conecta al importar).
  La lógica que necesita una sesión usa SQLite en memoria.
- Sin red, sin MinIO, sin SMTP.
- Sin reloj real: las reglas de tiempo reciben/parchean la hora.
"""
import os

# Deben fijarse ANTES de importar cualquier módulo de `app`.
os.environ.setdefault("SECRET_KEY", "clave-solo-para-pruebas-unitarias-0123456789")
os.environ.setdefault("ALGORITHM", "HS256")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_PORT", "5432")
os.environ.setdefault("DB_USER", "test")
os.environ.setdefault("DB_PASSWORD", "test")
os.environ.setdefault("DB_NAME", "test")

import pytest  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402


@pytest.fixture()
def db():
    """Sesión SQLite en memoria, aislada por test (solo tablas necesarias)."""
    from app.models.login_attempt_model import LoginAttempt, LoginBlock

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    LoginAttempt.__table__.create(engine)
    LoginBlock.__table__.create(engine)
    session = sessionmaker(bind=engine, autocommit=False, autoflush=False)()
    try:
        yield session
    finally:
        session.close()
        engine.dispose()


# ==========================================
# Semana 4 — pruebas de API con TestClient
# ==========================================
class _Api:
    def __init__(self, client, sesion):
        self.client = client
        self.db = sesion  # FakeSession: lo que "devuelve la BD" en este test


@pytest.fixture()
def api():
    """TestClient de la app real con la BD reemplazada por un FakeSession.

    - app.dependency_overrides[get_db]: ningún endpoint toca PostgreSQL.
    - Sin `with TestClient(...)`: no corre el lifespan (crear tablas,
      buckets de MinIO), así que tampoco se necesita infraestructura.
    - raise_server_exceptions=False: un error 500 se ve como lo vería el
      frontend (respuesta HTTP), no como una excepción en el test.
    - Se limpian los contadores del rate limit para que los tests no se
      bloqueen entre sí.
    """
    from fastapi.testclient import TestClient

    from app.config.database import get_db
    from app.main import app
    from app.utils import rate_limit
    from tests.fakes import FakeSession

    rate_limit._attempts.clear()
    sesion = FakeSession()
    app.dependency_overrides[get_db] = lambda: sesion
    try:
        yield _Api(TestClient(app, raise_server_exceptions=False), sesion)
    finally:
        app.dependency_overrides.clear()


# ==========================================
# Semana 6 — Integración con la BD real
# ==========================================
# La conexión llega SOLO por DATABASE_URL: no hay credenciales en los tests.
# Sin esa variable los tests de integración se saltan, así que el CI actual
# (que no tiene BD) sigue en verde. Se rechaza cualquier BD cuyo nombre no
# termine en "_test" para no correr nunca contra la de desarrollo.
@pytest.fixture(scope="session")
def db_engine():
    url = os.environ.get("DATABASE_URL")
    if not url:
        pytest.skip("necesita DATABASE_URL (BD de pruebas, ver README sección 9)")
    from sqlalchemy.engine import make_url

    nombre = make_url(url).database or ""
    if not nombre.endswith("_test"):
        pytest.fail(f"DATABASE_URL apunta a '{nombre}': solo se permite una BD que termine en _test")
    engine = create_engine(url)
    yield engine
    engine.dispose()


@pytest.fixture()
def db_session(db_engine):
    """Sesión real de PostgreSQL que se deshace al final de cada test.

    Estrategia de limpieza: ROLLBACK. Todo el test ocurre dentro de una
    transacción que nunca se confirma. Con join_transaction_mode=
    "create_savepoint", los commit() del código bajo prueba confirman un
    savepoint y no la transacción del test, así que igual se deshacen.
    """
    from sqlalchemy.orm import Session

    with db_engine.connect() as connection:
        transaction = connection.begin()
        session = Session(bind=connection, join_transaction_mode="create_savepoint")
        try:
            yield session
        finally:
            session.close()
            transaction.rollback()
