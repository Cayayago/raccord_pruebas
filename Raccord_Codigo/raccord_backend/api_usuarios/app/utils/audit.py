import json
import logging
import re
import uuid
from typing import Any, Optional

from app.config.database import SessionLocal
from app.models.user_model import User  # noqa: F401
from app.models.project_model import Project  # noqa: F401
from app.models.audit_log_model import AuditLog

logger = logging.getLogger("raccord")

# Claves cuyo valor nunca debe quedar en la auditoría.
_SENSITIVE = re.compile(
    r"pass|contrasena|token|jwt|jti|codigo|code|secret|authorization|api_key|apikey",
    re.IGNORECASE,
)
_MAX_DETAILS = 2000


def _sanitize(value: Any, depth: int = 0) -> Any:
    if depth > 4:
        return "[...]"
    if isinstance(value, dict):
        return {
            str(k): ("[OCULTO]" if _SENSITIVE.search(str(k)) else _sanitize(v, depth + 1))
            for k, v in value.items()
        }
    if isinstance(value, (list, tuple)):
        return [_sanitize(v, depth + 1) for v in list(value)[:50]]
    if value is None or isinstance(value, (bool, int, float, str)):
        return value
    return str(value)


def _to_uuid(value: Any) -> Optional[uuid.UUID]:
    if value is None:
        return None
    try:
        return value if isinstance(value, uuid.UUID) else uuid.UUID(str(value))
    except (ValueError, AttributeError):
        return None


def get_client_info(request) -> tuple:
    """IP y user-agent. No se confía en X-Forwarded-For (es falsificable)."""
    if request is None:
        return None, None
    ip = request.client.host if request.client else None
    ua = request.headers.get("user-agent")
    return ip, (ua[:500] if ua else None)


def log_event(
    action: str,
    module: str,
    success: bool,
    request=None,
    user_id: Any = None,
    project_id: Any = None,
    entity_type: Optional[str] = None,
    entity_id: Any = None,
    details: Optional[dict] = None,
) -> bool:
    """Registra un evento en audit_logs usando una sesión PROPIA.

    Sesión propia = el registro se guarda aunque la transacción de la
    operación haga rollback (clave para intentos de login fallidos).
    Nunca lanza excepción: si falla, se anota en el log y devuelve False.
    """
    ip, ua = get_client_info(request)
    db = SessionLocal()
    try:
        texto = None
        if details:
            texto = json.dumps(_sanitize(details), ensure_ascii=False, default=str)[:_MAX_DETAILS]
        db.add(
            AuditLog(
                id_user=_to_uuid(user_id),
                id_project=_to_uuid(project_id),
                action=action[:100],
                module=module[:50],
                entity_type=entity_type[:50] if entity_type else None,
                entity_id=str(entity_id)[:100] if entity_id is not None else None,
                ip_address=ip[:45] if ip else None,
                user_agent=ua,
                success=bool(success),
                details=texto,
            )
        )
        db.commit()
        return True
    except Exception:
        db.rollback()
        logger.exception("No se pudo registrar el evento de auditoría: %s", action)
        return False
    finally:
        db.close()
