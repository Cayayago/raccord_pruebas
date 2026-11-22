"""Interfaz propia para avisar al usuario (hoy por correo SMTP).

Los controladores no llaman a smtplib ni a ``app.utils.mail`` directo:
reciben un ``Notifier``. En producción FastAPI entrega ``SmtpNotifier``
con ``get_notifier``; en las pruebas se reemplaza por un doble con
``app.dependency_overrides[get_notifier]`` sin tocar la librería.
"""
from typing import Protocol

from app.utils import mail


class Notifier(Protocol):
    def recovery_code(self, destinatario: str, codigo: str) -> bool:
        """Envía el código de recuperación. True si salió, False si no."""
        ...


class SmtpNotifier:
    def recovery_code(self, destinatario: str, codigo: str) -> bool:
        return mail.send_recovery_email(destinatario, codigo)


def get_notifier() -> Notifier:
    return SmtpNotifier()
