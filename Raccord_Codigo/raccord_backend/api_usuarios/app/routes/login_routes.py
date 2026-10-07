from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config.database import get_db

from app.schemas.login_schema import (
    LoginSchema,
    TwoFactorSendSchema,
    TwoFactorVerifySchema
)

from app.controllers.login_controller import (
    login_user,
    check_2fa_required,
    send_2fa_code,
    verify_2fa_code,
    logout_user
)

from app.utils.rate_limit import rate_limit
from app.middleware.auth import get_current_user

# ==========================================
# ROUTER (público, es el punto de entrada de sesión)
# ==========================================
router = APIRouter(
    prefix="/users",
    tags=["Auth - Login"]
)


# LOGIN
# 8 intentos por minuto por IP: suficiente margen para un usuario que
# se equivoca de contraseña un par de veces, pero corta un ataque de
# fuerza bruta/credential-stuffing automatizado.
@router.post("/login")
def login(
    user: LoginSchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("login", max_attempts=8, window_seconds=60)),
):
    return login_user(user.mail, user.contrasena, db)


# LOGOUT
# Requiere estar autenticado (el propio token es lo que se va a
# revocar). Ver app/utils/token_revocation.py y
# app/middleware/auth.py: desde acá en adelante, ESTE token deja de
# servir contra la API aunque su firma y su "exp" sigan siendo
# válidos.
@router.post("/logout")
def logout(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    return logout_user(current_user, db)


# 2FA - VERIFICAR SI NECESITA 2FA
@router.post("/2fa/check")
def check_2fa(
    data: TwoFactorSendSchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("2fa-check", max_attempts=10, window_seconds=60)),
):
    return check_2fa_required(data.mail, data.device_id, data.contrasena, db)


# 2FA - ENVIAR CODIGO
@router.post("/2fa/send")
def send_2fa(
    data: TwoFactorSendSchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("2fa-send", max_attempts=5, window_seconds=300)),
):
    return send_2fa_code(data.mail, data.device_id, data.contrasena, db)


# 2FA - VERIFICAR CODIGO
# Límite más estricto: es el endpoint que emite el token de sesión, y
# el código son solo 6 dígitos (10^6 combinaciones) — sin límite de
# intentos se podría probar por fuerza bruta en minutos.
@router.post("/2fa/verify")
def verify_2fa(
    data: TwoFactorVerifySchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("2fa-verify", max_attempts=8, window_seconds=300)),
):
    return verify_2fa_code(data.mail, data.codigo, data.device_id, data.contrasena, db)
