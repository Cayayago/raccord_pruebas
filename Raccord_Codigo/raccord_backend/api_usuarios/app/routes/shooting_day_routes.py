from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.shooting_day_controller import (
    get_shooting_days,
    get_shooting_day,
    create_shooting_day,
    update_shooting_day_full,
    update_shooting_day,
    delete_shooting_day
)
from app.schemas.shooting_day_schema import ShootingDaySchema, ShootingDayUpdateSchema
from app.models.shooting_day_model import ShootingDay

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py.
from app.middleware.auth import get_current_user
from app.utils.project_scope import (
    require_project_member,
    require_record_project_permission,
    check_project_permission,
)
from app.utils.module_access import check_module_view_access

router = APIRouter()

# Antes /shooting-days sin filtro devolvía el plan de rodaje de TODOS
# los proyectos.
@router.get("/shooting-days/project/{id_project}")
def shooting_days(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "plan_rodaje", current_user.get("id_rol"))
    return get_shooting_days(id_project, db)

@router.get("/shooting-days/{id}")
def shooting_day(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=ShootingDay, pk_column="id_rodaje", not_found_message="Día de rodaje no encontrado",
    )),
):
    return get_shooting_day(id, db)

# Mismo permiso que crear escenas: Administrador (1001) y Director
# (1002) arman el plan de rodaje; el resto de roles solo lo consulta —
# resuelto dentro del proyecto al que dice pertenecer el día.
@router.post("/shooting-days")
def store_shooting_day(day: ShootingDaySchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, day.id_project, "create_scenes")
    return create_shooting_day(day, db)

@router.put("/shooting-days/{id}")
def edit_shooting_day(
    id: str,
    day: ShootingDaySchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=ShootingDay, pk_column="id_rodaje", not_found_message="Día de rodaje no encontrado",
    )),
):
    return update_shooting_day_full(id, day, db)

@router.patch("/shooting-days/{id}")
def patch_shooting_day(
    id: str,
    day: ShootingDayUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=ShootingDay, pk_column="id_rodaje", not_found_message="Día de rodaje no encontrado",
    )),
):
    return update_shooting_day(id, day, db)

@router.delete("/shooting-days/{id}")
def destroy_shooting_day(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=ShootingDay, pk_column="id_rodaje", not_found_message="Día de rodaje no encontrado",
    )),
):
    return delete_shooting_day(id, db)
