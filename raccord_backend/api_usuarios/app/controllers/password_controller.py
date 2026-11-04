import random
import string
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.user_model import User
from app.utils.hash import hash_password
from app.utils.response import api_response
from app.utils.mail import send_recovery_email

# ==========================================
# CODIGOS DE RECUPERACION
# ==========================================
recovery_codes = {}


# ==========================================
# RECOVER PASSWORD (enviar código)
# ==========================================
def recover_password(mail: str, db: Session):
    user = db.query(User).filter(User.mail == mail).first()

    if not user:
        return api_response(False, "Correo no registrado", error="USER_NOT_FOUND")

    codigo = ''.join(random.choices(string.digits, k=6))

    recovery_codes[mail] = {
        "codigo": codigo,
        "expira": datetime.now() + timedelta(minutes=15)
    }

    enviado = send_recovery_email(mail, codigo)

    if not enviado:
        return api_response(False, "Error al enviar correo", error="MAIL_ERROR")

    return api_response(True, "Código de recuperación enviado al correo")


# ==========================================
# RESET PASSWORD (cambiar contraseña)
# ==========================================
def reset_password(mail: str, codigo: str, nueva_contrasena: str, db: Session):
    if mail not in recovery_codes:
        return api_response(False, "No hay solicitud de recuperación", error="NO_REQUEST")

    datos = recovery_codes[mail]

    if datetime.now() > datos["expira"]:
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
