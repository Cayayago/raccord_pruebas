from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config.database import get_db

from app.schemas.password_schema import RecoverSchema, ResetPasswordSchema

from app.controllers.password_controller import recover_password, reset_password

from app.utils.rate_limit import rate_limit

# ==========================================
# ROUTER (público: se usa antes de tener sesión)
# ==========================================
router = APIRouter(
    prefix="/users",
    tags=["Auth - Password"]
)


# RECOVER PASSWORD
# Límite bajo: cada llamada exitosa manda un correo real. Sin esto,
# alguien podría usar este endpoint para saturar de correos la bandeja
# de cualquier usuario registrado.
@router.post("/recover-password")
def recover(
    data: RecoverSchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("recover-password", max_attempts=5, window_seconds=300)),
):
    return recover_password(data.mail, db)


# RESET PASSWORD
# El código son 6 dígitos: sin límite de intentos se podría probar por
# fuerza bruta antes de que expire (15 minutos).
@router.post("/reset-password")
def reset(
    data: ResetPasswordSchema,
    db: Session = Depends(get_db),
    _rl=Depends(rate_limit("reset-password", max_attempts=10, window_seconds=300)),
):
    return reset_password(data.mail, data.codigo, data.nueva_contrasena, db)
