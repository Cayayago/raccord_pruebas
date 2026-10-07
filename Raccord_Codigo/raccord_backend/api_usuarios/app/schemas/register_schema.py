from pydantic import BaseModel, EmailStr, Field
from typing import Optional


# ==========================================
# REGISTRO (Cliente/Empresa + Usuario)
# ==========================================
class RegisterSchema(BaseModel):
    # Datos empresa
    razon_social: str
    representante_legal: str
    email_empresa: EmailStr
    address: Optional[str] = None
    telephone: Optional[str] = None
    number_cellphone: Optional[str] = None
    document: str
    id_document: str

    # Datos usuario
    nombre: str
    apellido: str
    mail: EmailStr
    msisdn: str
    contrasena: str = Field(min_length=8, max_length=72)


# ==========================================
# INVITAR USUARIOS A UN PROYECTO
# ==========================================
# Un invitado = una fila del formulario "Invitar al equipo" (nombre
# completo, correo, área/departamento, rol). "Invitar persona" manda
# una lista de un solo elemento; "Carga masiva" (Excel/CSV/JSON) manda
# la misma estructura con N filas — mismo endpoint para ambos casos.
class InviteItemSchema(BaseModel):
    nombre_completo: str
    mail: EmailStr
    id_departamento: str
    id_rol: int


class InviteSchema(BaseModel):
    invitados: list[InviteItemSchema]
    id_project: str
    id_client: str
