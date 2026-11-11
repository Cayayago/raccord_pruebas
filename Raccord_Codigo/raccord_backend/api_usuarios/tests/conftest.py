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
