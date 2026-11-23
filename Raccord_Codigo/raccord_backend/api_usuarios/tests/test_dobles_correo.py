"""Semana 5 — Dobles de prueba (Deiver, capa API).

Dependencias que el backend no controla en la recuperación de contraseña:
- El correo (SMTP de Gmail): envuelto en la interfaz propia ``Notifier``
  (``app/utils/notifier.py``). Los tests reemplazan ``Notifier``, nunca
  ``smtplib``.
- La hora actual: el código vence a los 15 minutos. ``recover_password`` y
  ``reset_password`` reciben ``now``; los tests le pasan un reloj fijo.

Regla que se prueba: el correo se manda una vez y con el código guardado,
no se manda cuando no debe, y el API resiste si el correo falla.
"""
from datetime import datetime, timedelta

import pytest

from app.controllers import password_controller
from app.controllers.password_controller import (
    CODIGO_VIGENCIA,
    recover_password,
    reset_password,
)
from app.models.user_model import User
from app.utils.notifier import get_notifier
from tests.fakes import FakeSession, Obj

CORREO = "deiver@raccord.co"
LAS_10 = datetime(2026, 11, 21, 10, 0, 0)


@pytest.fixture(autouse=True)
def _sin_codigos_previos():
    password_controller.recovery_codes.clear()
    yield
    password_controller.recovery_codes.clear()


def _bd_con_usuario():
    # Fake: FakeSession es una BD en memoria que de verdad responde consultas.
    return FakeSession({User: Obj(mail=CORREO, contrasena="hash-viejo")})


class NotificadorEnMemoria:
    """Fake: implementa Notifier guardando los correos en una lista
    en lugar de mandarlos. Sirve para verificar ESTADO (qué quedó en la
    bandeja) sin depender de cómo se llamó."""

    def __init__(self):
        self.bandeja = []

    def recovery_code(self, destinatario, codigo):
        self.bandeja.append((destinatario, codigo))
        return True


# ------------------------------------------------------------------
# Comportamiento: con qué se llamó y que NO se llamó (spy)
# ------------------------------------------------------------------
def test_recover_sends_the_stored_code_once_to_the_user(mocker):
    # Spy: mocker.Mock() registra las llamadas; se le pide que devuelva True
    # como el SMTP real cuando el correo sale.
    notifier = mocker.Mock()
    notifier.recovery_code.return_value = True

    respuesta = recover_password(CORREO, _bd_con_usuario(), notifier, now=lambda: LAS_10)

    assert respuesta["success"] is True
    codigo_guardado = password_controller.recovery_codes[CORREO]["codigo"]
    # Comportamiento: UNA vez, al correo del usuario, con el MISMO código que
    # quedó guardado (si se mandara otro, el usuario no podría cambiar la clave).
    notifier.recovery_code.assert_called_once_with(CORREO, codigo_guardado)


def test_recover_does_not_send_mail_when_user_does_not_exist(mocker):
    # Spy: solo interesa comprobar que NO se usó.
    notifier = mocker.Mock()

    respuesta = recover_password(CORREO, FakeSession({User: None}), notifier)

    assert respuesta["error"] == "USER_NOT_FOUND"
    notifier.recovery_code.assert_not_called()
    assert CORREO not in password_controller.recovery_codes


# ------------------------------------------------------------------
# Estado: qué quedó guardado (fake)
# ------------------------------------------------------------------
def test_recover_stores_a_six_digit_code_that_expires_in_15_minutes():
    # Fake (NotificadorEnMemoria) + reloj fijo (stub de la hora actual).
    notificador = NotificadorEnMemoria()

    recover_password(CORREO, _bd_con_usuario(), notificador, now=lambda: LAS_10)

    guardado = password_controller.recovery_codes[CORREO]
    assert guardado["expira"] == LAS_10 + timedelta(minutes=15)
    assert len(guardado["codigo"]) == 6 and guardado["codigo"].isdigit()
    assert notificador.bandeja == [(CORREO, guardado["codigo"])]


# ------------------------------------------------------------------
# Resiliencia: el correo falla (stub)
# ------------------------------------------------------------------
def test_recover_answers_mail_error_instead_of_500_when_smtp_raises(mocker, caplog):
    # Stub: el notificador siempre lanza la excepción que daría smtplib
    # con Gmail caído. No se verifica cómo se llamó, solo qué hace el API.
    notifier = mocker.Mock()
    notifier.recovery_code.side_effect = ConnectionRefusedError("smtp caído")

    respuesta = recover_password(CORREO, _bd_con_usuario(), notifier)

    assert respuesta["success"] is False
    assert respuesta["error"] == "MAIL_ERROR"
    assert "smtp caído" in caplog.text
    # Hallazgo S5: el código quedaba vigente aunque el usuario nunca lo recibió.
    assert CORREO not in password_controller.recovery_codes


def test_recover_answers_mail_error_when_notifier_returns_false(mocker):
    # Stub: respuesta enlatada False (así responde send_recovery_email
    # cuando atrapa el error internamente).
    notifier = mocker.Mock()
    notifier.recovery_code.return_value = False

    respuesta = recover_password(CORREO, _bd_con_usuario(), notifier)

    assert respuesta["error"] == "MAIL_ERROR"
    assert CORREO not in password_controller.recovery_codes


def test_recover_endpoint_responds_json_not_500_when_mail_fails(api, mocker):
    # Stub inyectado en el endpoint real con dependency_overrides: el API
    # completo (validación, rate limit, ruta, controlador) con el correo caído.
    from app.main import app

    caido = mocker.Mock()
    caido.recovery_code.side_effect = TimeoutError("smtp.gmail.com no responde")
    app.dependency_overrides[get_notifier] = lambda: caido
    api.db.results[User] = Obj(mail=CORREO, contrasena="hash-viejo")

    response = api.client.post("/users/recover-password", json={"mail": CORREO})

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    assert response.json()["error"] == "MAIL_ERROR"
    caido.recovery_code.assert_called_once()


# ------------------------------------------------------------------
# El reloj: valores límite del vencimiento (stub de la hora)
# ------------------------------------------------------------------
@pytest.mark.parametrize(
    "transcurrido, esperado",
    [
        (CODIGO_VIGENCIA - timedelta(seconds=1), True),   # 14:59 → sirve
        (CODIGO_VIGENCIA, True),                          # 15:00 justo → sirve
        (CODIGO_VIGENCIA + timedelta(seconds=1), False),  # 15:01 → vencido
    ],
)
def test_reset_respects_the_15_minute_limit(transcurrido, esperado):
    # Stub del reloj: now() devuelve una hora fija; no hay que esperar 15 min.
    notificador = NotificadorEnMemoria()
    db = _bd_con_usuario()
    recover_password(CORREO, db, notificador, now=lambda: LAS_10)
    _, codigo = notificador.bandeja[0]

    respuesta = reset_password(
        CORREO, codigo, "NuevaClave123", db, now=lambda: LAS_10 + transcurrido
    )

    assert respuesta["success"] is esperado
    if not esperado:
        assert respuesta["error"] == "CODE_EXPIRED"
        assert db.commits == 0  # estado: la contraseña no se tocó


# ------------------------------------------------------------------
# El adaptador real delega en app.utils.mail (sin SMTP)
# ------------------------------------------------------------------
def test_smtp_notifier_delegates_to_the_mail_module(mocker):
    # Mock de nuestro propio módulo (no de smtplib): se comprueba que el
    # adaptador pasa los datos tal cual y devuelve lo que diga el correo.
    from app.utils.notifier import SmtpNotifier

    enviar = mocker.patch("app.utils.mail.send_recovery_email", return_value=True)

    assert SmtpNotifier().recovery_code(CORREO, "123456") is True
    enviar.assert_called_once_with(CORREO, "123456")
