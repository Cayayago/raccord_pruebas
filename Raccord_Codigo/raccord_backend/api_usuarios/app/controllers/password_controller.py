import logging
import random
import string
from datetime import datetime, timedelta
from typing import Callable, Optional

from sqlalchemy.orm import Session

from app.models.user_model import User
from app.utils.hash import hash_password
from app.utils.response import api_response
from app.utils.notifier import Notifier, SmtpNotifier

logger = logging.getLogger("raccord")

CODIGO_VIGENCIA = timedelta(minutes=15)

# ==========================================
# CODIGOS DE RECUPERACION
# ==========================================
recovery_codes = {}


# ==========================================
# RECOVER PASSWORD (enviar código)
# ==========================================
# notifier y now se reciben como parámetro (semana 5): el correo y la hora
# actual son dependencias que el backend no controla. Por defecto se usan
# las reales, así que las llamadas existentes no cambian.
def recover_password(
    mail: str,
    db: Session,
    notifier: Optional[Notifier] = None,
    now: Callable[[], datetime] = datetime.now,
):
    notifier = notifier or SmtpNotifier()
    user = db.query(User).filter(User.mail == mail).first()

    if not user:
        return api_response(False, "Correo no registrado", error="USER_NOT_FOUND")

    codigo = ''.join(random.choices(string.digits, k=6))

    recovery_codes[mail] = {
        "codigo": codigo,
        "expira": now() + CODIGO_VIGENCIA
    }

    # Si el servidor de correo se cae (excepción) el API no debe responder
    # 500: se registra y se responde MAIL_ERROR, igual que si devolviera False.
    try:
        enviado = notifier.recovery_code(mail, codigo)
    except Exception as error:
        logger.warning("No se pudo enviar el código de recuperación: %s", error)
        enviado = False

    if not enviado:
        # Un código que el usuario nunca recibió no debe quedar vigente.
        recovery_codes.pop(mail, None)
        return api_response(False, "Error al enviar correo", error="MAIL_ERROR")

    return api_response(True, "Código de recuperación enviado al correo")


# ==========================================
# RESET PASSWORD (cambiar contraseña)
# ==========================================
def reset_password(
    mail: str,
    codigo: str,
    nueva_contrasena: str,
    db: Session,
    now: Callable[[], datetime] = datetime.now,
):
    if mail not in recovery_codes:
        return api_response(False, "No hay solicitud de recuperación", error="NO_REQUEST")

    datos = recovery_codes[mail]

    if now() > datos["expira"]:
        del recovery_codes[mail]
        return api_response(False, "Código expirado", error="CODE_EXPIRED")

    if datos["codigo"] != codigo:
        return api_response(False, "Código incorrecto", error="INVALID_CODE")

    user = db.query(User).filter(User.mail == mail).first()

    if not user:
        return api_response(False, "Usuario no encontrado", error="USER_NOT_FOUND")

    user.contrasena = hash_password(nueva_contrasena)
    db.commit()

    del recovery_codes[mail]

    return api_response(True, "Contraseña actualizada correctamente")
