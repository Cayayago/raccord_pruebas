"""Limitador por IP en memoria (app/utils/rate_limit.py). Reloj parcheado."""
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.utils import rate_limit as rl


@pytest.fixture(autouse=True)
def limpiar_estado():
    rl._attempts.clear()
    yield
    rl._attempts.clear()


@pytest.fixture()
def reloj(monkeypatch):
    estado = {"t": 1000.0}
    monkeypatch.setattr(rl.time, "time", lambda: estado["t"])
    return estado


def _req(ip="1.2.3.4"):
    return SimpleNamespace(client=SimpleNamespace(host=ip))


def test_permite_hasta_el_maximo_y_rechaza_el_siguiente(reloj):
    dep = rl.rate_limit("login", 3, 60)
    for _ in range(3):
        dep(_req())  # 1.º, 2.º y 3.º pasan (límite exacto)
    with pytest.raises(HTTPException) as e:
        dep(_req())  # 4.º: 429
    assert e.value.status_code == 429


def test_retry_after_indica_segundos_restantes_de_la_ventana(reloj):
    dep = rl.rate_limit("login", 1, 60)
    dep(_req())
    reloj["t"] += 10
    with pytest.raises(HTTPException) as e:
        dep(_req())
    assert e.value.headers["Retry-After"] == "51"  # 60 - 10 + 1


def test_tras_expirar_la_ventana_se_vuelve_a_permitir(reloj):
    dep = rl.rate_limit("login", 1, 60)
    dep(_req())
    reloj["t"] += 60  # justo en el borde: el intento viejo ya no cuenta (< 60)
    dep(_req())


def test_un_segundo_antes_de_expirar_sigue_bloqueado(reloj):
    dep = rl.rate_limit("login", 1, 60)
    dep(_req())
    reloj["t"] += 59
    with pytest.raises(HTTPException):
        dep(_req())


def test_ips_distintas_tienen_contadores_independientes(reloj):
    dep = rl.rate_limit("login", 1, 60)
    dep(_req("1.1.1.1"))
    dep(_req("2.2.2.2"))  # no lanza


def test_prefijos_distintos_tienen_contadores_independientes(reloj):
    rl.rate_limit("login", 1, 60)(_req())
    rl.rate_limit("registro", 1, 60)(_req())  # no lanza


def test_sin_cliente_se_agrupa_como_unknown(reloj):
    dep = rl.rate_limit("login", 1, 60)
    dep(SimpleNamespace(client=None))
    with pytest.raises(HTTPException):
        dep(SimpleNamespace(client=None))
