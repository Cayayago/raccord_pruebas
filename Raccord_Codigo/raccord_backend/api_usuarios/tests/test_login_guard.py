"""RNF-004: bloqueo por intentos fallidos (app/utils/login_guard.py).

Se usa SQLite en memoria (fixture `db`) y el reloj se fija parcheando
`login_guard.datetime`, así los tests son deterministas.
"""
from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.models.login_attempt_model import LoginAttempt, LoginBlock
from app.utils import login_guard as lg

AHORA = datetime(2026, 10, 20, 12, 0, 0)
MAIL = "ana@raccord.com"
IP = "10.0.0.1"


class _RelojFijo:
    """Sustituto de `datetime` dentro de login_guard."""

    actual = AHORA

    @classmethod
    def utcnow(cls):
        return cls.actual


@pytest.fixture(autouse=True)
def reloj(monkeypatch):
    _RelojFijo.actual = AHORA
    monkeypatch.setattr(lg, "datetime", _RelojFijo)
    return _RelojFijo


def _fallar(db, veces, mail=MAIL, ip=IP):
    for _ in range(veces):
        lg.register_failure(db, mail, ip)


def _bloqueado(db, mail=MAIL, ip=IP) -> bool:
    try:
        lg.assert_not_blocked(db, mail, ip)
        return False
    except HTTPException as e:
        assert e.status_code == 429
        return True


# ------------------------------------------------ regla 1: 5 fallos / 15 min
def test_cuatro_fallos_no_bloquean_la_cuenta(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA - 1)
    assert _bloqueado(db) is False


def test_quinto_fallo_bloquea_la_cuenta(db):
    # Valor límite exacto: 5 = bloqueo.
    _fallar(db, lg.MAX_FALLOS_CUENTA)
    assert _bloqueado(db) is True


def test_bloqueo_de_cuenta_vence_a_los_15_minutos(db, reloj):
    _fallar(db, lg.MAX_FALLOS_CUENTA)
    reloj.actual = AHORA + lg.BLOQUEO_CUENTA - timedelta(seconds=1)
    assert _bloqueado(db) is True  # 1 s antes: sigue bloqueada
    reloj.actual = AHORA + lg.BLOQUEO_CUENTA + timedelta(seconds=1)
    assert _bloqueado(db) is False  # 1 s después: libre


def test_fallos_fuera_de_la_ventana_de_15_min_no_suman(db, reloj):
    _fallar(db, lg.MAX_FALLOS_CUENTA - 1)
    reloj.actual = AHORA + lg.VENTANA_CUENTA + timedelta(seconds=1)
    _fallar(db, 1)  # el 5.º, pero los 4 anteriores ya salieron de la ventana
    assert _bloqueado(db) is False


def test_bloqueo_de_una_cuenta_no_afecta_a_otra(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA, mail="a@x.com", ip="1.1.1.1")
    assert _bloqueado(db, mail="b@x.com", ip="2.2.2.2") is False


def test_correo_se_normaliza_mayusculas_y_espacios(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA, mail="  ANA@Raccord.COM ")
    assert _bloqueado(db, mail="ana@raccord.com") is True


def test_mensaje_de_bloqueo_es_generico_y_trae_retry_after(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA)
    with pytest.raises(HTTPException) as e:
        lg.assert_not_blocked(db, MAIL, IP)
    assert e.value.detail == lg.MENSAJE_BLOQUEO
    assert e.value.headers["Retry-After"] == "900"


def test_correo_inexistente_se_bloquea_igual_que_uno_real(db):
    # No debe poder usarse el login para averiguar qué correos existen.
    _fallar(db, lg.MAX_FALLOS_CUENTA, mail="no-existe@x.com")
    assert _bloqueado(db, mail="no-existe@x.com") is True


# ------------------------------------------------ regla 2: 20 fallos por IP / 1 h
def test_veinte_fallos_de_una_ip_con_correos_distintos_bloquean_la_ip(db):
    for i in range(lg.MAX_FALLOS_IP):
        lg.register_failure(db, f"user{i}@x.com", IP)
    assert _bloqueado(db, mail="otro-nuevo@x.com", ip=IP) is True


def test_diecinueve_fallos_de_una_ip_no_bloquean(db):
    for i in range(lg.MAX_FALLOS_IP - 1):
        lg.register_failure(db, f"user{i}@x.com", IP)
    assert _bloqueado(db, mail="otro-nuevo@x.com", ip=IP) is False


def test_ip_unknown_nunca_se_bloquea_por_ip(db):
    # Sin IP identificable no se puede bloquear "a todos los desconocidos".
    for i in range(lg.MAX_FALLOS_IP + 5):
        lg.register_failure(db, f"user{i}@x.com", "unknown")
    assert _bloqueado(db, mail="nuevo@x.com", ip="unknown") is False


# ------------------------------------------------ regla 3: 10 fallos / 24 h => admin
def test_diez_fallos_en_24h_exigen_desbloqueo_de_administrador(db, reloj):
    # Fallos espaciados (>15 min) para no activar la regla de 15 minutos.
    for i in range(lg.MAX_FALLOS_24H):
        reloj.actual = AHORA + timedelta(hours=2 * i % 20, minutes=i)
        lg.register_failure(db, MAIL, f"9.9.9.{i}")
    reloj.actual = AHORA + timedelta(hours=23)
    assert _bloqueado(db, ip="8.8.8.8") is True
    reloj.actual = AHORA + timedelta(days=30)  # no vence solo
    assert db.query(LoginBlock).filter_by(clave=f"admin:{MAIL}").one().hasta is None


def test_bloqueo_permanente_nunca_se_acorta(db):
    db.add(LoginBlock(clave="cuenta:x@x.com", hasta=None))
    db.commit()
    lg._poner_bloqueo(db, "cuenta:x@x.com", AHORA + timedelta(minutes=15))
    db.commit()
    assert db.query(LoginBlock).one().hasta is None


# ------------------------------------------------ éxito y desbloqueo
def test_login_correcto_borra_los_fallos_de_esa_cuenta(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA - 1)
    lg.register_success(db, MAIL)
    _fallar(db, 1)  # sería el 5.º si no se hubieran borrado
    assert _bloqueado(db) is False


def test_login_correcto_no_borra_fallos_de_otra_cuenta(db):
    _fallar(db, 3, mail="otra@x.com")
    lg.register_success(db, MAIL)
    assert db.query(LoginAttempt).filter_by(mail="otra@x.com").count() == 3


def test_administrador_desbloquea_cuenta_y_borra_fallos(db):
    _fallar(db, lg.MAX_FALLOS_CUENTA)
    assert _bloqueado(db, ip="3.3.3.3") is True
    lg.unblock_account(db, MAIL)
    assert _bloqueado(db, ip="3.3.3.3") is False
    assert db.query(LoginAttempt).filter_by(mail=MAIL).count() == 0


# ------------------------------------------------ IP del cliente
@pytest.mark.parametrize(
    "confiar, cabecera, cliente, esperado",
    [
        ("false", "5.5.5.5, 6.6.6.6", "7.7.7.7", "7.7.7.7"),  # cabecera falsificable: se ignora
        ("true", "5.5.5.5, 6.6.6.6", "7.7.7.7", "5.5.5.5"),   # primera IP del proxy
        ("true", None, "7.7.7.7", "7.7.7.7"),                   # sin cabecera, usa el socket
        ("TRUE", " 5.5.5.5 ", "7.7.7.7", "5.5.5.5"),            # mayúsculas y espacios
    ],
)
def test_client_ip(monkeypatch, confiar, cabecera, cliente, esperado):
    monkeypatch.setenv("TRUST_PROXY_HEADERS", confiar)
    headers = {"x-forwarded-for": cabecera} if cabecera else {}
    req = SimpleNamespace(headers=headers, client=SimpleNamespace(host=cliente))
    assert lg.client_ip(req) == esperado


def test_client_ip_sin_cliente_devuelve_unknown():
    req = SimpleNamespace(headers={}, client=None)
    assert lg.client_ip(req) == "unknown"
