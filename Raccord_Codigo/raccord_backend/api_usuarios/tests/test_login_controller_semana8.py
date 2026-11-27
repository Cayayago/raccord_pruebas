"""Semana 8 (cobertura backend ≥ 80 %) — login_controller (seguridad).

Reglas que protege:
- correo inexistente y contraseña mala responden IGUAL (no se puede enumerar usuarios);
- cada fallo se cuenta (bloqueo por intentos) y un acierto limpia el contador;
- una cuenta suspendida, o suspendida en TODOS sus proyectos, no entra;
- el 2FA exige contraseña en cada paso y el código vence / no se reutiliza.
Sin BD: FakeSession + dobles de login_guard, hash y correo.
"""
from datetime import datetime, timedelta

import pytest

from app.controllers import login_controller as lc
from app.models.user_model import User
from app.models.user_project_model import UserProject
from tests.fakes import FakeSession, Obj

MAIL = "ana@raccord.test"


def _usuario(**attrs):
    base = dict(
        id_user="11111111-1111-1111-1111-111111111111", mail=MAIL, nombre="Ana", apellido="Ruiz",
        id_rol=1001, id_departamento=None, id_client="c1", contrasena="hash", estado="activo",
        ultimo_acceso=None,
    )
    base.update(attrs)
    return Obj(**base)


@pytest.fixture
def guardia(monkeypatch):
    """Dobles de login_guard que registran qué se llamó."""
    llamadas = {"bloqueo": [], "fallos": [], "aciertos": []}
    monkeypatch.setattr(lc, "assert_not_blocked", lambda db, m, ip: llamadas["bloqueo"].append((m, ip)))
    monkeypatch.setattr(lc, "register_failure", lambda db, m, ip: llamadas["fallos"].append((m, ip)))
    monkeypatch.setattr(lc, "register_success", lambda db, m: llamadas["aciertos"].append(m))
    return llamadas


@pytest.fixture
def clave_ok(monkeypatch):
    monkeypatch.setattr(lc, "verify_password", lambda plano, hash_: True)


@pytest.fixture(autouse=True)
def limpiar_2fa():
    lc.verified_devices.clear()
    lc.two_factor_codes.clear()
    yield
    lc.verified_devices.clear()
    lc.two_factor_codes.clear()


def _db(user, estados=None):
    return FakeSession({User: user, UserProject.estado: [(e,) for e in (estados or [])]})


# ---------------- credenciales ----------------
def test_correo_inexistente_y_clave_mala_responden_igual(guardia, monkeypatch):
    monkeypatch.setattr(lc, "verify_password", lambda plano, hash_: False)
    sin_usuario = lc.login_user(MAIL, "x", _db(None), "1.1.1.1")
    clave_mala = lc.login_user(MAIL, "x", _db(_usuario()), "1.1.1.1")

    assert sin_usuario == clave_mala
    assert sin_usuario["success"] is False
    assert sin_usuario["error"] == "INVALID_CREDENTIALS"
    # los dos casos cuentan como fallo para el bloqueo por intentos
    assert guardia["fallos"] == [(MAIL, "1.1.1.1")] * 2
    assert guardia["aciertos"] == []


def test_el_bloqueo_se_revisa_antes_de_mirar_la_clave(guardia, monkeypatch):
    def bloqueado(db, mail, ip):
        raise RuntimeError("bloqueado")

    monkeypatch.setattr(lc, "assert_not_blocked", bloqueado)
    monkeypatch.setattr(lc, "verify_password", lambda *a: pytest.fail("no debe verificar la clave"))
    with pytest.raises(RuntimeError):
        lc.login_user(MAIL, "x", _db(_usuario()))


def test_hash_corrupto_responde_auth_error_y_no_500(guardia, monkeypatch):
    def rota(plano, hash_):
        raise ValueError("hash inválido")

    monkeypatch.setattr(lc, "verify_password", rota)
    r = lc.login_user(MAIL, "x", _db(_usuario()))
    assert (r["success"], r["error"]) == (False, "AUTH_ERROR")


def test_usuario_suspendido_no_entra_aunque_la_clave_sea_buena(guardia, clave_ok):
    r = lc.login_user(MAIL, "ok", _db(_usuario(estado="suspendido")))
    assert (r["success"], r["error"]) == (False, "USER_SUSPENDED")
    # la clave era correcta: se limpian los fallos previos
    assert guardia["aciertos"] == [MAIL]


def test_suspendido_en_todos_sus_proyectos_no_entra(guardia, clave_ok):
    r = lc.login_user(MAIL, "ok", _db(_usuario(), ["suspendido", "suspendido"]))
    assert (r["success"], r["error"]) == (False, "USER_SUSPENDED")


def test_suspendido_solo_en_algunos_proyectos_si_entra(guardia, clave_ok):
    r = lc.login_user(MAIL, "ok", _db(_usuario(), ["suspendido", "activo"]))
    assert r["success"] is True


# ---------------- login / logout ----------------
def test_login_exitoso_entrega_token_y_datos_del_usuario(guardia, clave_ok):
    user = _usuario()
    db = _db(user)
    r = lc.login_user(MAIL, "ok", db)

    assert r["success"] is True and r["message"] == "Login exitoso"
    assert r["data"]["token_type"] == "Bearer" and r["data"]["access_token"]
    assert r["data"]["usuario"]["mail"] == MAIL
    assert r["data"]["usuario"]["id_client"] == "c1"
    assert db.commits == 1 and user.ultimo_acceso is not None
    assert "contrasena" not in r["data"]["usuario"]


def test_primer_ingreso_de_un_invitado_lo_pasa_de_pendiente_a_activo(guardia, clave_ok):
    user = _usuario(estado="pendiente")
    lc.login_user(MAIL, "ok", _db(user))
    assert user.estado == "activo"


def test_logout_revoca_el_token_del_que_cierra_sesion(monkeypatch):
    revocados = []
    monkeypatch.setattr(lc, "revoke_token", lambda db, jti, exp: revocados.append((jti, exp)))
    r = lc.logout_user({"jti": "abc", "exp": 123}, FakeSession())
    assert r["success"] is True
    assert revocados == [("abc", 123)]


# ---------------- 2FA ----------------
def test_check_2fa_exige_clave_aunque_el_2fa_este_apagado(guardia, monkeypatch):
    monkeypatch.setattr(lc, "verify_password", lambda *a: False)
    r = lc.check_2fa_required(MAIL, "dev", "mala", _db(_usuario()))
    assert r["error"] == "INVALID_CREDENTIALS"


def test_check_2fa_con_el_interruptor_global_no_pide_codigo(guardia, clave_ok, monkeypatch):
    monkeypatch.setattr(lc, "TWO_FACTOR_GLOBALLY_DISABLED", True)
    r = lc.check_2fa_required(MAIL, "dev", "ok", _db(_usuario()))
    assert r["data"] == {"requires_2fa": False}


def test_check_2fa_activo_pide_codigo_a_un_dispositivo_nuevo_y_no_a_uno_confiable(guardia, clave_ok, monkeypatch):
    monkeypatch.setattr(lc, "TWO_FACTOR_GLOBALLY_DISABLED", False)
    nuevo = lc.check_2fa_required(MAIL, "dev", "ok", _db(_usuario()))
    assert nuevo["data"] == {"requires_2fa": True}

    lc.verified_devices[f"{MAIL}:dev"] = datetime.now() + timedelta(hours=1)
    conocido = lc.check_2fa_required(MAIL, "dev", "ok", _db(_usuario()))
    assert conocido["data"] == {"requires_2fa": False}


def test_dispositivo_con_la_confianza_vencida_vuelve_a_pedir_verificacion(guardia, clave_ok, monkeypatch):
    monkeypatch.setattr(lc, "TWO_FACTOR_GLOBALLY_DISABLED", False)
    lc.verified_devices[f"{MAIL}:dev"] = datetime.now() - timedelta(seconds=1)
    r = lc.check_2fa_required(MAIL, "dev", "ok", _db(_usuario()))
    assert r["data"] == {"requires_2fa": True}
    assert f"{MAIL}:dev" not in lc.verified_devices  # se borra al vencer


def test_send_2fa_guarda_un_codigo_de_6_digitos_que_vence_en_10_minutos(guardia, clave_ok, monkeypatch):
    enviados = []
    monkeypatch.setattr(lc, "send_2fa_email", lambda mail, codigo: enviados.append((mail, codigo)) or True)
    r = lc.send_2fa_code(MAIL, "dev", "ok", _db(_usuario()))

    assert r["data"] == {"requires_2fa": True}
    guardado = lc.two_factor_codes[MAIL]
    assert len(guardado["codigo"]) == 6 and guardado["codigo"].isdigit()
    assert enviados == [(MAIL, guardado["codigo"])]
    assert timedelta(minutes=9) < guardado["expira"] - datetime.now() <= timedelta(minutes=10)


def test_send_2fa_si_el_correo_falla_avisa_mail_error(guardia, clave_ok, monkeypatch):
    monkeypatch.setattr(lc, "send_2fa_email", lambda mail, codigo: False)
    r = lc.send_2fa_code(MAIL, "dev", "ok", _db(_usuario()))
    assert (r["success"], r["error"]) == (False, "MAIL_ERROR")


def test_send_2fa_a_un_dispositivo_confiable_no_envia_correo(guardia, clave_ok, monkeypatch):
    monkeypatch.setattr(lc, "send_2fa_email", lambda *a: pytest.fail("no debe enviar correo"))
    lc.verified_devices[f"{MAIL}:dev"] = datetime.now() + timedelta(hours=1)
    r = lc.send_2fa_code(MAIL, "dev", "ok", _db(_usuario()))
    assert r["data"] == {"requires_2fa": False}


def test_send_2fa_con_clave_mala_no_genera_codigo(guardia, monkeypatch):
    monkeypatch.setattr(lc, "verify_password", lambda *a: False)
    r = lc.send_2fa_code(MAIL, "dev", "mala", _db(_usuario()))
    assert r["error"] == "INVALID_CREDENTIALS"
    assert MAIL not in lc.two_factor_codes


def test_verify_2fa_sin_codigo_pendiente(guardia, clave_ok):
    r = lc.verify_2fa_code(MAIL, "123456", "dev", "ok", _db(_usuario()))
    assert r["error"] == "NO_CODE"


def test_verify_2fa_con_codigo_vencido_lo_borra(guardia, clave_ok):
    lc.two_factor_codes[MAIL] = {"codigo": "123456", "device_id": "dev", "expira": datetime.now() - timedelta(seconds=1)}
    r = lc.verify_2fa_code(MAIL, "123456", "dev", "ok", _db(_usuario()))
    assert r["error"] == "CODE_EXPIRED"
    assert MAIL not in lc.two_factor_codes


def test_verify_2fa_con_codigo_incorrecto_no_da_sesion(guardia, clave_ok):
    lc.two_factor_codes[MAIL] = {"codigo": "123456", "device_id": "dev", "expira": datetime.now() + timedelta(minutes=5)}
    r = lc.verify_2fa_code(MAIL, "000000", "dev", "ok", _db(_usuario()))
    assert r["error"] == "INVALID_CODE"
    assert MAIL in lc.two_factor_codes  # sigue pendiente


def test_verify_2fa_con_clave_mala_no_da_sesion_ni_con_el_codigo_bueno(guardia, monkeypatch):
    monkeypatch.setattr(lc, "verify_password", lambda *a: False)
    lc.two_factor_codes[MAIL] = {"codigo": "123456", "device_id": "dev", "expira": datetime.now() + timedelta(minutes=5)}
    r = lc.verify_2fa_code(MAIL, "123456", "dev", "mala", _db(_usuario()))
    assert r["error"] == "INVALID_CREDENTIALS"


def test_verify_2fa_correcto_da_sesion_confia_en_el_dispositivo_y_gasta_el_codigo(guardia, clave_ok):
    user = _usuario(estado="pendiente")
    lc.two_factor_codes[MAIL] = {"codigo": "123456", "device_id": "dev", "expira": datetime.now() + timedelta(minutes=5)}
    r = lc.verify_2fa_code(MAIL, "123456", "dev", "ok", _db(user))

    assert r["success"] is True
    assert r["data"]["usuario"]["device_verified"] is True
    assert user.estado == "activo"
    assert f"{MAIL}:dev" in lc.verified_devices
    assert MAIL not in lc.two_factor_codes  # el código no se puede reutilizar
