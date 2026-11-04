from pydantic import BaseModel, EmailStr


# ==========================================
# LOGIN
# ==========================================
class LoginSchema(BaseModel):
    mail: EmailStr
    contrasena: str


# ==========================================
# 2FA (segundo factor, parte del flujo de login)
# ==========================================
class TwoFactorSendSchema(BaseModel):
    mail: EmailStr
    device_id: str
    contrasena: str


class TwoFactorVerifySchema(BaseModel):
    mail: EmailStr
    codigo: str
    device_id: str
    contrasena: str
