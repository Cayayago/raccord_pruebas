
import json

from sqlalchemy.orm import Session

from app.models.audit_log_model import AuditLog
from app.models.user_model import User
from app.models.project_model import Project
from app.utils.response import api_response


def get_audit_logs(
    db: Session,
    page: int = 1,
    limit: int = 20,
    action: str | None = None,
    module: str | None = None,
    success: bool | None = None,
):
    """Consulta paginada de eventos de auditoría."""

    query = db.query(AuditLog)

    if action:
        query = query.filter(AuditLog.action.ilike(f"%{action}%"))

    if module:
        query = query.filter(AuditLog.module.ilike(f"%{module}%"))

    if success is not None:
        query = query.filter(AuditLog.success == success)

    total = query.count()

    rows = (
        query.order_by(AuditLog.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )

    logs = []

    for log in rows:
        user = db.query(User).filter(User.id_user == log.id_user).first() if log.id_user else None
        project = (
            db.query(Project)
            .filter(Project.id_project == log.id_project)
            .first()
            if log.id_project
            else None
        )

        details = None
        if log.details:
            try:
                details = json.loads(log.details)
            except (ValueError, TypeError):
                details = log.details

        logs.append({
            "id_audit": str(log.id_audit),
            "created_at": log.created_at.isoformat() if log.created_at else None,
            "user": (
                f"{user.nombre} {user.apellido}".strip()
                if user
                else "Sistema o usuario no disponible"
            ),
            "id_user": str(log.id_user) if log.id_user else None,
            "project": project.project_name if project else None,
            "id_project": str(log.id_project) if log.id_project else None,
            "action": log.action,
            "module": log.module,
            "entity_type": log.entity_type,
            "entity_id": log.entity_id,
            "ip_address": log.ip_address,
            "success": log.success,
            "details": details,
        })

    return api_response(
        True,
        "Registros de auditoría consultados correctamente",
        {
            "items": logs,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": total,
                "pages": (total + limit - 1) // limit,
            },
        },
    )
[]