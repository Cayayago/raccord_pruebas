import logging
import random
import string
from datetime import datetime, timedelta

from sqlalchemy.orm import Session
from sqlalchemy.sql import func

logger = logging.getLogger("raccord")

from app.models.user_model import User

from app.utils.hash import verify_password
from app.utils.security import create_access_token
from app.utils.response import api_response
from app.utils.mail import send_2fa_email
from app.utils.token_revocation import revoke_token

# ==========================================
# 2FA - INTERRUPTOR GLOBAL (TEMPORAL)
# ==========================================
# Suspendido a pedido explícito (2026-08-27): mientras esté en True,
# check_2fa_required() siempre responde requires_2fa=False (tras validar
# igual mail+contraseña), así que el frontend nunca navega a la pantalla
# de código. No se tocó send_2fa_code/verify_2fa_code ni el modelo: para
# reactivar, basta con volver esto a False.
TWO_FACTOR_GLOBALLY_DISABLED = True

# ==========================================
# 2FA - DISPOSITIVOS VERIFICADOS / CODIGOS
# ==========================================
# Cuánto tiempo se confía en un dispositivo ya verificado antes de
# volver a pedir código de verificación.
DEVICE_TRUST_HOURS = 12

verified_devices = {}
two_factor_codes = {}


# ==========================================
# OBTENER id_client A PARTIR DEL USUARIO
# ==========================================
# id_client vive directamente en users.id_client (ver
# sql/011_users_id_client.sql) — se setea al crear el usuario (registro
# propio o invitación), NO se deriva de sus proyectos. Antes se
# calculaba vía user_projects -> projects.id_client, pero eso fallaba
# para un usuario recién registrado que todavía no tiene ningún
# proyecto (justo el caso de la pantalla obligatoria "Registra
# Proyecto" tras crear la cuenta).
def _get_client_from_user(user: User, db: Session):
    return user.id_client


# ==========================================
# CONSTRUIR RESPUESTA DE SESION (TOKEN + USUARIO)
# ==========================================
def _build_session_response(user: User, db: Session, message: str, extra: dict = None):
    # id_user es UUID (uuid.UUID) en el modelo: hay que convertirlo a
    # str explícitamente porque jose.jwt.encode no sabe serializar
    # objetos UUID (a diferencia de la respuesta JSON de FastAPI, que sí
    # lo hace sola vía jsonable_encoder).
    token = create_access_token({
        "id_user": str(user.id_user),
        "mail": user.mail,
        "id_rol": user.id_rol
    })

    data = {
        "access_token": token,
        "token_type": "Bearer",
        "usuario": {
            "id_user": user.id_user,
            "nombre": user.nombre,
            "apellido": user.apellido,
            "mail": user.mail,
            "id_rol": user.id_rol,
            "id_departamento": user.id_departamento,
            "id_client": _get_client_from_user(user, db)
        }
    }

    if extra:
        data["usuario"].update(extra)

    return api_response(True, message, data)


# ==========================================
# VALIDAR CREDENCIALES (mail + contraseña)
# ==========================================
# Punto único de verificación de contraseña. Se usa tanto en el login
# directo como en CADA paso del flujo de 2FA (check/send/verify).
#
# IMPORTANTE: antes, check_2fa_required/send_2fa_code/verify_2fa_code
# no recibían ni validaban la contraseña en absoluto — solo dependían
# de mail + device_id + código. Eso significa que con cualquier
# contraseña (correcta o no) se podía llegar hasta la pantalla de 2FA,
# y si se tenía el código (enviado al correo real), se obtenía sesión
# igual, sin que la contraseña importara. Ahora la contraseña se
# revalida en cada paso, incluido verify_2fa_code, que es el punto
# donde realmente se emite el token.
    # Mensaje único e indistinguible para "correo no existe" y
    # "contraseña incorrecta": si se devolviera un mensaje distinto para
    # cada caso, alguien podría usar el login como oráculo para
    # confirmar qué correos están registrados (enumeración de
    # usuarios), probando direcciones al azar. Con el mismo texto y el
    # mismo código de error en ambos casos, esa distinción desaparece
    # del todo lado del cliente.
def _credenciales_invalidas():
    return api_response(
        False,
        "Verifica tu correo y tu contraseña: alguno de los dos no es correcto.",
        error="INVALID_CREDENTIALS",
    )


def _validar_credenciales(mail: str, contrasena: str, db: Session):
    user = db.query(User).filter(User.mail == mail).first()

    if not user:
        return None, _credenciales_invalidas()

    try:
        password_ok = verify_password(contrasena, user.contrasena)
    except Exception:
        # Ej: hash corrupto/formato incompatible en la BD. No debe
        # tumbar la petición con un 500 crudo.
        logger.exception("Error verificando contraseña para %s", mail)
        return None, api_response(False, "No fue posible validar las credenciales", error="AUTH_ERROR")

    if not password_ok:
        return None, _credenciales_invalidas()

    # Suspendido por un Administrador/Director (o el Jefe de su propio
    # departamento) desde "Roles del Equipo" — no se borra ninguna de
    # sus escenas/fotos/etc., simplemente no puede volver a entrar hasta
    # que alguien con permiso lo reactive.
    if user.estado == "suspendido":
        return None, api_response(
            False,
            "Tu acceso a este proyecto fue suspendido. Contacta a un administrador de tu equipo.",
            error="USER_SUSPENDED"
        )

    return user, None


# ==========================================
# LOGIN
# ==========================================
def login_user(mail: str, contrasena: str, db: Session):
    user, error = _validar_credenciales(mail, contrasena, db)

    if error:
        return error

    # Primer ingreso real de un usuario invitado: "pendiente" (invitación
    # enviada, todavía no entró) pasa a "activo" (ya usó el sistema).
    if user.estado == "pendiente":
        user.estado = "activo"

    user.ultimo_acceso = func.now()
    db.commit()

    return _build_session_response(user, db, "Login exitoso")


# ==========================================
# LOGOUT (revocación real del JWT actual)
# ==========================================
# current_user es el payload YA decodificado del token que se está
# cerrando (viene de Depends(get_current_user), ver login_routes.py),
# así que jti/exp son los del propio token — no hace falta volver a
# tocar el usuario en BD para esto.
def logout_user(current_user: dict, db: Session):
    revoke_token(db, current_user.get("jti"), current_user.get("exp"))
    return api_response(True, "Sesión cerrada correctamente")


# ==========================================
# 2FA - ¿EL DISPOSITIVO YA ESTA VERIFICADO?
# ==========================================
def _device_is_verified(mail: str, device_id: str) -> bool:
    key = f"{mail}:{device_id}"
    expira = verified_devices.get(key)

    if not expira:
        return False

    if datetime.now() > expira:
        # ventana de confianza vencida, se debe volver a verificar
        del verified_devices[key]
        return False

    return True


# ==========================================
# 2FA - VERIFICAR SI DISPOSITIVO NECESITA 2FA
# ==========================================
# Un dispositivo ya verificado dentro de la ventana de confianza
# (DEVICE_TRUST_HOURS) no vuelve a pedir código. Si es un dispositivo
# nuevo, o pasó la ventana, sí se requiere.
#
# La contraseña se valida PRIMERO, siempre: si está mal, no importa si
# el dispositivo es confiable o no, se corta acá con INVALID_PASSWORD.
def check_2fa_required(mail: str, device_id: str, contrasena: str, db: Session):
    _, error = _validar_credenciales(mail, contrasena, db)

    if error:
        return error

    if TWO_FACTOR_GLOBALLY_DISABLED:
        return api_response(True, "2FA suspendido temporalmente", {
            "requires_2fa": False
        })

    if _device_is_verified(mail, device_id):
        return api_response(True, "Dispositivo confiable, no se requiere verificación", {
            "requires_2fa": False
        })

    return api_response(True, "Se requiere verificación", {
        "requires_2fa": True
    })


# ==========================================
# 2FA - ENVIAR CODIGO
# ==========================================
def send_2fa_code(mail: str, device_id: str, contrasena: str, db: Session):
    user, error = _validar_credenciales(mail, contrasena, db)

    if error:
        return error

    if _device_is_verified(mail, device_id):
        return api_response(True, "Dispositivo confiable, no se requiere verificación", {
            "requires_2fa": False
        })

    codigo = ''.join(random.choices(string.digits, k=6))

    two_factor_codes[mail] = {
        "codigo": codigo,
        "device_id": device_id,
        "expira": datetime.now() + timedelta(minutes=10)
    }

    enviado = send_2fa_email(mail, codigo)

    if not enviado:
        return api_response(False, "Error al enviar código", error="MAIL_ERROR")

    return api_response(True, "Código de verificación enviado al correo", {
        "requires_2fa": True
    })


# ==========================================
# 2FA - VERIFICAR CODIGO
# ==========================================
# Este es el paso que realmente emite el token de sesión, así que es
# el más importante para revalidar la contraseña: aunque alguien se
# salte la pantalla de login y llame este endpoint directo, no puede
# obtener sesión sin la contraseña correcta, solo con el código.
def verify_2fa_code(mail: str, codigo: str, device_id: str, contrasena: str, db: Session):
    user, error = _validar_credenciales(mail, contrasena, db)

    if error:
        return error

    if mail not in two_factor_codes:
        return api_response(False, "No hay código de verificación pendiente", error="NO_CODE")

    datos = two_factor_codes[mail]

    if datetime.now() > datos["expira"]:
        del two_factor_codes[mail]
        return api_response(False, "Código expirado", error="CODE_EXPIRED")

    if datos["codigo"] != codigo:
        return api_response(False, "Código incorrecto", error="INVALID_CODE")

    key = f"{mail}:{device_id}"
    verified_devices[key] = datetime.now() + timedelta(hours=DEVICE_TRUST_HOURS)

    del two_factor_codes[mail]

    # Mismo caso que login_user: primer ingreso real de un invitado.
    if user.estado == "pendiente":
        user.estado = "activo"

    user.ultimo_acceso = func.now()
    db.commit()

    return _build_session_response(
        user, db, "Verificación exitosa", extra={"device_verified": True}
    )
