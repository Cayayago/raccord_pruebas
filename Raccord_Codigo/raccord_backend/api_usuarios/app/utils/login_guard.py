import os
from datetime import datetime, timedelta

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session

from app.models.login_attempt_model import LoginAttempt, LoginBlock

# ==========================================
# RNF-004 — BLOQUEO POR INTENTOS FALLIDOS DE LOGIN
# ==========================================
#   1) 5 fallos por cuenta en 15 min  -> cuenta bloqueada 15 min.
#   2) 20 fallos desde una IP en 1 h  -> IP bloqueada 1 h.
#   3) 10 fallos por cuenta en 24 h   -> cuenta bloqueada hasta que un
#      administrador la desbloquee (POST /users/{id}/desbloquear).
# Un login correcto borra los fallos de ESA cuenta (no los de la IP).
#
# Todos los bloqueos devuelven el MISMO mensaje, exista o no el correo.
MAX_FALLOS_CUENTA = 5
VENTANA_CUENTA = timedelta(minutes=15)
BLOQUEO_CUENTA = timedelta(minutes=15)

MAX_FALLOS_IP = 20
VENTANA_IP = timedelta(hours=1)
BLOQUEO_IP = timedelta(hours=1)

MAX_FALLOS_24H = 10
VENTANA_24H = timedelta(hours=24)

MENSAJE_BLOQUEO = (
    "Demasiados intentos fallidos. Por seguridad el acceso está bloqueado "
    "temporalmente. Inténtalo de nuevo más tarde o contacta a un administrador."
)


def norm_mail(mail: str) -> str:
    return (mail or "").strip().lower()


def client_ip(request: Request) -> str:
    # Detrás de un proxy (nginx/Caddy en producción) la IP real viene en
    # X-Forwarded-For; solo se confía en ese encabezado si se activa
    # TRUST_PROXY_HEADERS=true (si no, cualquiera podría falsearlo para
    # evitar el bloqueo por IP).
    if os.getenv("TRUST_PROXY_HEADERS", "false").lower() == "true":
        fwd = request.headers.get("x-forwarded-for")
        if fwd:
            return fwd.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _bloqueo_activo(db: Session, clave: str, ahora: datetime) -> bool:
    b = db.query(LoginBlock).filter(LoginBlock.clave == clave).first()
    if not b:
        return False
    if b.hasta is None or b.hasta > ahora:
        return True
    db.delete(b)  # venció: se limpia
    db.commit()
    return False


def _poner_bloqueo(db: Session, clave: str, hasta):
    b = db.query(LoginBlock).filter(LoginBlock.clave == clave).first()
    if b:
        # Un bloqueo permanente (hasta=None) nunca se acorta.
        if b.hasta is not None:
            b.hasta = hasta
    else:
        db.add(LoginBlock(clave=clave, hasta=hasta))


def assert_not_blocked(db: Session, mail: str, ip: str):
    """Se llama ANTES de mirar la contraseña. Lanza 429 si hay bloqueo."""
    ahora = datetime.utcnow()
    m = norm_mail(mail)
    if (
        (ip != "unknown" and _bloqueo_activo(db, f"ip:{ip}", ahora))
        or _bloqueo_activo(db, f"admin:{m}", ahora)
        or _bloqueo_activo(db, f"cuenta:{m}", ahora)
    ):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=MENSAJE_BLOQUEO,
            headers={"Retry-After": "900"},
        )


def register_failure(db: Session, mail: str, ip: str):
    """Registra un intento fallido y activa los bloqueos que correspondan."""
    ahora = datetime.utcnow()
    m = norm_mail(mail)

    db.add(LoginAttempt(mail=m, ip=ip, fecha=ahora))
    db.flush()

    # Limpieza: ya nada de más de 24 h sirve para ninguna regla.
    db.query(LoginAttempt).filter(LoginAttempt.fecha < ahora - VENTANA_24H).delete()

    def fallos_cuenta(ventana):
        return (
            db.query(LoginAttempt)
            .filter(LoginAttempt.mail == m, LoginAttempt.fecha >= ahora - ventana)
            .count()
        )

    if fallos_cuenta(VENTANA_24H) >= MAX_FALLOS_24H:
        _poner_bloqueo(db, f"admin:{m}", None)
    elif fallos_cuenta(VENTANA_CUENTA) >= MAX_FALLOS_CUENTA:
        _poner_bloqueo(db, f"cuenta:{m}", ahora + BLOQUEO_CUENTA)

    if ip != "unknown":
        fallos_ip = (
            db.query(LoginAttempt)
            .filter(LoginAttempt.ip == ip, LoginAttempt.fecha >= ahora - VENTANA_IP)
            .count()
        )
        if fallos_ip >= MAX_FALLOS_IP:
            _poner_bloqueo(db, f"ip:{ip}", ahora + BLOQUEO_IP)

    db.commit()


def register_success(db: Session, mail: str):
    """Login correcto: se olvidan los fallos previos de esa cuenta."""
    m = norm_mail(mail)
    db.query(LoginAttempt).filter(LoginAttempt.mail == m).delete()
    db.query(LoginBlock).filter(LoginBlock.clave == f"cuenta:{m}").delete()
    db.commit()


def unblock_account(db: Session, mail: str):
    """Reset por administrador: quita todos los bloqueos y fallos de la cuenta."""
    m = norm_mail(mail)
    db.query(LoginBlock).filter(
        LoginBlock.clave.in_([f"cuenta:{m}", f"admin:{m}"])
    ).delete(synchronize_session=False)
    db.query(LoginAttempt).filter(LoginAttempt.mail == m).delete()
    db.commit()
