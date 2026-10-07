from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# ==========================================
# USUARIO (CRUD)
# ==========================================
class UserSchema(BaseModel):
    nombre: str
    apellido: str
    identificacion: str
    id_identificacion: str
    mail: EmailStr
    msisdn: str
    direccion: str
    fecha_de_nacimiento: datetime
    estado: str
    contrasena: str = Field(min_length=8, max_length=72)
    id_departamento: str
    id_rol: int


class UserUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    identificacion: Optional[str] = None
    id_identificacion: Optional[str] = None
    mail: Optional[EmailStr] = None
    msisdn: Optional[str] = None
    direccion: Optional[str] = None
    fecha_de_nacimiento: Optional[datetime] = None
    estado: Optional[str] = None
    contrasena: Optional[str] = Field(default=None, min_length=8, max_length=72)
    id_departamento: Optional[str] = None
    id_rol: Optional[int] = None


# ==========================================
# AUTO-EDICIÓN DE PERFIL (PATCH /users/me)
# ==========================================
# A propósito NO incluye mail, id_rol ni estado ni contrasena:
# cualquier usuario autenticado puede llamar este endpoint sobre SU
# PROPIO registro (nunca el de otro), así que estos campos quedan
# estructuralmente fuera de su alcance — ni con un request manual
# (Thunder Client, curl, etc.) se pueden colar, porque Pydantic
# simplemente no los conoce en este schema. Cambiar el correo o el rol
# sigue siendo exclusivo de PATCH /users/{id} (requiere permiso
# "full_management"). La contraseña se cambia aparte, con verificación
# de la actual (ver ChangePasswordSchema).
#
# id_departamento SÍ se incluye, pero el controller (update_own_profile)
# lo ignora si quien llama no es Administrador (1001) o Director
# (1002) — el resto de roles ve su departamento de solo lectura en el
# frontend, pero igual se valida acá por si acaso.
class UserProfileUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    identificacion: Optional[str] = None
    id_identificacion: Optional[str] = None
    msisdn: Optional[str] = None
    direccion: Optional[str] = None
    fecha_de_nacimiento: Optional[datetime] = None
    id_departamento: Optional[str] = None


# ==========================================
# CAMBIO DE CONTRASEÑA (usuario autenticado, sobre sí mismo)
# ==========================================
class ChangePasswordSchema(BaseModel):
    contrasena_actual: str
    nueva_contrasena: str = Field(min_length=8, max_length=72)


# ==========================================
# SUSPENDER / REACTIVAR (PATCH /users/{id}/estado)
# ==========================================
# Solo dos valores válidos acá — "pendiente" no se asigna manualmente,
# es un estado transitorio que el propio login pasa a "activo" en el
# primer ingreso (ver login_controller._validar_credenciales /
# login_user). El controller (set_user_estado) valida el resto de
# reglas (quién puede tocar a quién) porque dependen de comparar el rol
# y departamento de quien llama contra los del usuario objetivo.
class UserEstadoSchema(BaseModel):
    estado: str


# ==========================================
# VINCULACIÓN USUARIO - PROYECTO
# ==========================================
class UserProjectSchema(BaseModel):
    id_user: str
    id_project: str
    id_rol: int = 1005
