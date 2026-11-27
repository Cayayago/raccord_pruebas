"""Semana 7 — el interruptor E2E_DISABLE_RATE_LIMIT.

Los límites por IP existen para proteger la app en producción. La suite E2E,
que corre en paralelo desde una sola IP, necesita que no la bloqueen; por eso
hay un interruptor que SOLO se enciende en el backend de pruebas. Estos tests
fijan las dos mitades: apagado, los límites siguen funcionando; encendido, no
estorban, y las reglas por cuenta del login no se tocan.
"""
import pytest
from fastapi import HTTPException

from app.utils import rate_limit as rl
from app.utils.login_guard import client_ip


class _Req:
    def __init__(self, host="1.2.3.4"):
        self.client = type("C", (), {"host": host})()
        self.headers = {}


@pytest.fixture(autouse=True)
def limpio(monkeypatch):
    monkeypatch.delenv("E2E_DISABLE_RATE_LIMIT", raising=False)
    monkeypatch.delenv("TRUST_PROXY_HEADERS", raising=False)
    rl._attempts.clear()
    yield
    rl._attempts.clear()


def test_por_defecto_el_interruptor_esta_apagado():
    assert rl.e2e_sin_limites() is False


@pytest.mark.parametrize("valor, esperado", [("true", True), ("TRUE", True), ("false", False), ("1", False), ("", False)])
def test_solo_el_valor_true_lo_enciende(monkeypatch, valor, esperado):
    monkeypatch.setenv("E2E_DISABLE_RATE_LIMIT", valor)

    assert rl.e2e_sin_limites() is esperado


def test_apagado_el_limite_por_ip_responde_429_al_pasarse():
    dependencia = rl.rate_limit("login-test", max_attempts=2, window_seconds=60)
    dependencia(_Req())
    dependencia(_Req())

    with pytest.raises(HTTPException) as error:
        dependencia(_Req())

    assert error.value.status_code == 429


def test_encendido_el_limite_por_ip_no_bloquea(monkeypatch):
    monkeypatch.setenv("E2E_DISABLE_RATE_LIMIT", "true")
    dependencia = rl.rate_limit("login-test", max_attempts=2, window_seconds=60)

    for _ in range(50):
        dependencia(_Req())  # no lanza


def test_encendido_el_login_no_cuenta_por_ip(monkeypatch):
    assert client_ip(_Req("9.9.9.9")) == "9.9.9.9"

    monkeypatch.setenv("E2E_DISABLE_RATE_LIMIT", "true")

    assert client_ip(_Req("9.9.9.9")) == "unknown"
