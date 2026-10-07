from app.schemas.contact_schema import ContactSchema
from app.utils.mail import send_contact_email
from app.utils.response import api_response


# SEND CONTACT
def send_contact(data: ContactSchema):
    # Honeypot: campo oculto que un humano nunca llena (ver
    # contact_schema.py). Si viene con contenido, es un bot — se
    # responde éxito SIN enviar el correo, para no llenar la bandeja de
    # spam ni delatarle al bot que fue detectado.
    if data.honeypot.strip():
        return api_response(True, "Mensaje enviado exitosamente")

    enviado = send_contact_email(
        nombre=data.nombre.strip(),
        email=data.email,
        celular=data.celular.strip() if data.celular else "",
        empresa=data.empresa.strip(),
        tipo=data.tipo.strip() or "demo",
        mensaje=data.mensaje.strip(),
    )

    if not enviado:
        return api_response(False, "Error al enviar el mensaje", error="MAIL_ERROR")

    return api_response(True, "Mensaje enviado exitosamente")