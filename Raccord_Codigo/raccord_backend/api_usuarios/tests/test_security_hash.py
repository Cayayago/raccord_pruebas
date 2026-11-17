"""JWT (app/utils/security.py) y hashing (app/utils/hash.py)."""
import calendar
from datetime import datetime, timedelta

import pytest
from jose import jwt

from app.utils import security
from app.utils.hash import hash_password, verify_password


# ---------------------------------------------------------------- JWT
def test_token_valido_conserva_los_datos_y_trae_jti_y_exp():
    # Arrange
    datos = {"sub": "usuario-1", "id_rol": 1002}
    # Act
    token = security.create_access_token(datos)
    payload = security.verify_token(token)
    # Assert
    assert payload["sub"] == "usuario-1"
    assert payload["id_rol"] == 1002
    assert "jti" in payload and "exp" in payload


def test_create_access_token_no_modifica_el_diccionario_original():
    datos = {"sub": "x"}
    security.create_access_token(datos)
    assert datos == {"sub": "x"}


def test_cada_token_tiene_jti_distinto():
    # El jti permite revocar un token puntual en el logout.
    t1 = security.create_access_token({"sub": "x"})
    t2 = security.create_access_token({"sub": "x"})
    assert security.verify_token(t1)["jti"] != security.verify_token(t2)["jti"]


def test_token_vencido_es_rechazado():
    # Determinista: el token se fabrica ya vencido, sin esperar ni usar el reloj.
    vencido = jwt.encode(
        {"sub": "x", "exp": datetime.utcnow() - timedelta(seconds=1)},
        security.SECRET_KEY,
        algorithm=security.ALGORITHM,
    )
    assert security.verify_token(vencido) is None


def test_token_que_vence_en_el_futuro_inmediato_es_aceptado():
    # Valor límite del lado válido de la expiración.
    vigente = jwt.encode(
        {"sub": "x", "exp": datetime.utcnow() + timedelta(seconds=30)},
        security.SECRET_KEY,
        algorithm=security.ALGORITHM,
    )
    assert security.verify_token(vigente)["sub"] == "x"


def test_la_expiracion_respeta_el_tiempo_configurado(monkeypatch):
    monkeypatch.setattr(security, "ACCESS_TOKEN_EXPIRE_MINUTES", 5)
    payload = security.verify_token(security.create_access_token({"sub": "x"}))
    ahora_utc = calendar.timegm(datetime.utcnow().utctimetuple())
    restante = payload["exp"] - ahora_utc
    assert 4 * 60 < restante <= 5 * 60 + 1


def test_token_firmado_con_otra_clave_es_rechazado():
    falso = jwt.encode({"sub": "x"}, "otra-clave", algorithm=security.ALGORITHM)
    assert security.verify_token(falso) is None


def test_token_manipulado_es_rechazado():
    token = security.create_access_token({"sub": "x"})
    cabecera, cuerpo, firma = token.split(".")
    assert security.verify_token(f"{cabecera}.{cuerpo}A.{firma}") is None


@pytest.mark.parametrize("basura", ["", "abc", "a.b.c", "Bearer xyz"])
def test_cadenas_que_no_son_jwt_devuelven_none(basura):
    assert security.verify_token(basura) is None


# ---------------------------------------------------------------- hash
def test_hash_no_es_la_contrasena_y_verifica():
    h = hash_password("Secreta123")
    assert h != "Secreta123"
    assert verify_password("Secreta123", h) is True


def test_contrasena_incorrecta_no_verifica():
    assert verify_password("otra", hash_password("Secreta123")) is False


def test_hash_usa_sal_distinta_en_cada_llamada():
    assert hash_password("misma") != hash_password("misma")


def test_hash_usa_bcrypt_con_12_rondas():
    # RNF-013: el costo viaja dentro del hash ($2b$12$...).
    assert hash_password("x").startswith("$2b$12$")


def test_contrasena_de_72_caracteres_se_diferencia_de_71():
    # Límite inferior del truncamiento de bcrypt: ambas se usan completas.
    base = "a" * 71
    h = hash_password(base)
    assert verify_password(base, h) is True
    assert verify_password("a" * 72, h) is False


def test_contrasena_mayor_a_72_se_trunca_de_forma_consistente():
    # Valor límite: del carácter 73 en adelante no influye (regla documentada).
    h = hash_password("a" * 72 + "XYZ")
    assert verify_password("a" * 72, h) is True
    assert verify_password("a" * 72 + "OTRA-COLA", h) is True
