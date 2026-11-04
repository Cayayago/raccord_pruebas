from pydantic import BaseModel, EmailStr, Field
from typing import Optional

# Formulario de "Contáctanos" de la landing (Landing_pages/Main.html) —
# es el único endpoint público sin autenticación de todo el backend, así
# que además de los tipos correctos (EmailStr valida formato real) se
# ponen límites de longitud razonables para no dejar la puerta abierta a
# payloads gigantes o basura.
#
# "honeypot" es un campo trampa: en el formulario real está oculto por
# CSS (nadie lo ve ni lo llena a mano), pero un bot que autocompleta
# todos los inputs sí lo hace. Si llega con algo adentro, el controller
# responde éxito sin enviar el correo — así el bot no aprende que fue
# bloqueado y no reintenta. Ver contact_controller.py.
class ContactSchema(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=120)
    email: EmailStr
    celular: Optional[str] = Field(default="", max_length=30)
    empresa: str = Field(default="", max_length=120)
    tipo: str = Field(default="demo", max_length=30)
    mensaje: str = Field(..., min_length=1, max_length=3000)
    honeypot: str = Field(default="", max_length=200)