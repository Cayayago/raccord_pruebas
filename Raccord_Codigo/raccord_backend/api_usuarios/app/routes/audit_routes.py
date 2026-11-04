
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.config.database import get_db
from app.middleware.auth import require_permission
from app.controllers.audit_controller import get_audit_logs

router = APIRouter()


@router.get("/audit-logs")
def list_audit_logs(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    action: str | None = Query(None, max_length=100),
    module: str | None = Query(None, max_length=50),
    success: bool | None = Query(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_permission("view_audit_logs")),
):
    return get_audit_logs(
        db=db,
        page=page,
        limit=limit,
        action=action,
        module=module,
        success=success,
    )

