from pydantic import BaseModel, EmailStr, Field


# ==========================================
# RECUPERACIÓN DE CONTRASEÑA
# ==========================================
class RecoverSchema(BaseModel):
    mail: EmailStr


class ResetPasswordSchema(BaseModel):
    mail: EmailStr
    codigo: str
    nueva_contrasena: str = Field(min_length=8, max_length=72)
