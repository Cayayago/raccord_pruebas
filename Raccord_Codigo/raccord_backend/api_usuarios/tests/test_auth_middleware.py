"""Middleware de autenticación/autorización y revocación de tokens."""
from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from jose import jwt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.middleware import auth
from app.models.revoked_token_model import RevokedToken
from app.utils import security, token_revocation as tr
from app.utils.permissions import ADMINISTRADOR, ONSET, USUARIO


@pytest.fixture()
def db_tokens():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    RevokedToken.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def _creds(token):
    return SimpleNamespace(credentials=token)


# ------------------------------------------------ get_current_user
def test_token_valido_devuelve_el_payload(db_tokens):
    token = security.create_access_token({"id_user": "u1", "id_rol": ONSET})
    payload = auth.get_current_user(_creds(token), db_tokens)
    assert payload["id_user"] == "u1" and payload["id_rol"] == ONSET


def test_token_invalido_da_401(db_tokens):
    with pytest.raises(HTTPException) as e:
        auth.get_current_user(_creds("no-es-un-jwt"), db_tokens)
    assert e.value.status_code == 401


def test_token_vencido_da_401(db_tokens):
    vencido = jwt.encode(
        {"sub": "x", "exp": datetime.utcnow() - timedelta(seconds=1)},
        security.SECRET_KEY, algorithm=security.ALGORITHM,
    )
    with pytest.raises(HTTPException) as e:
        auth.get_current_user(_creds(vencido), db_tokens)
    assert e.value.status_code == 401


def test_token_revocado_en_logout_da_401(db_tokens):
    token = security.create_access_token({"id_user": "u1"})
    p = security.verify_token(token)
    tr.revoke_token(db_tokens, p["jti"], p["exp"])
    with pytest.raises(HTTPException) as e:
        auth.get_current_user(_creds(token), db_tokens)
    assert e.value.status_code == 401
    assert "Sesión cerrada" in e.value.detail


# ------------------------------------------------ require_roles / require_permission
def test_require_roles_permite_rol_listado():
    dep = auth.require_roles(ADMINISTRADOR)
    assert dep(current_user={"id_rol": ADMINISTRADOR})["id_rol"] == ADMINISTRADOR


def test_require_roles_rechaza_rol_no_listado():
    with pytest.raises(HTTPException) as e:
        auth.require_roles(ADMINISTRADOR)(current_user={"id_rol": USUARIO})
    assert e.value.status_code == 403


def test_require_permission_permite_con_permiso():
    dep = auth.require_permission("upload_photos")
    assert dep(current_user={"id_rol": ONSET})["id_rol"] == ONSET


def test_require_permission_rechaza_sin_permiso():
    with pytest.raises(HTTPException) as e:
        auth.require_permission("upload_photos")(current_user={"id_rol": USUARIO})
    assert e.value.status_code == 403


def test_require_permission_rechaza_token_sin_rol():
    with pytest.raises(HTTPException):
        auth.require_permission("upload_photos")(current_user={})


# ------------------------------------------------ revocación
def test_revocar_sin_jti_o_sin_exp_no_hace_nada(db_tokens):
    tr.revoke_token(db_tokens, None, 123)
    tr.revoke_token(db_tokens, "abc", None)
    assert db_tokens.query(RevokedToken).count() == 0


def test_revocar_dos_veces_el_mismo_token_no_duplica(db_tokens):
    exp = int((datetime.utcnow() + timedelta(hours=1)).timestamp())
    tr.revoke_token(db_tokens, "j1", exp)
    tr.revoke_token(db_tokens, "j1", exp)
    assert db_tokens.query(RevokedToken).count() == 1


def test_is_token_revoked(db_tokens):
    exp = int((datetime.utcnow() + timedelta(hours=1)).timestamp())
    tr.revoke_token(db_tokens, "j1", exp)
    assert tr.is_token_revoked(db_tokens, "j1") is True
    assert tr.is_token_revoked(db_tokens, "otro") is False
    assert tr.is_token_revoked(db_tokens, None) is False


def test_revocar_limpia_los_jti_ya_expirados(db_tokens):
    db_tokens.add(RevokedToken(jti="viejo", fecha_expira=datetime.utcnow() - timedelta(hours=1)))
    db_tokens.commit()
    tr.revoke_token(db_tokens, "nuevo", int((datetime.utcnow() + timedelta(hours=1)).timestamp()))
    jtis = {r.jti for r in db_tokens.query(RevokedToken).all()}
    assert jtis == {"nuevo"}
