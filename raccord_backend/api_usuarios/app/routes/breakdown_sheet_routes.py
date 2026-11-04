from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.breakdown_sheet_controller import (
    get_breakdown_sheets,
    get_breakdown_sheet,
    create_breakdown_sheet,
    update_breakdown_sheet_full,
    update_breakdown_sheet,
    delete_breakdown_sheet
)
from app.schemas.breakdown_sheet_schema import BreakdownSheetSchema, BreakdownSheetUpdateSchema
from app.models.breakdown_sheet_model import BreakdownSheet

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

# Antes /breakdown-sheets sin filtro devolvía los desgloses de TODOS
# los proyectos.
@router.get("/breakdown-sheets/project/{id_project}")
def breakdown_sheets(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "desglose", current_user.get("id_rol"))
    return get_breakdown_sheets(id_project, db)

@router.get("/breakdown-sheets/{id}")
def breakdown_sheet(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=BreakdownSheet, pk_column="id_desglose", not_found_message="Desglose no encontrado",
    )),
):
    return get_breakdown_sheet(id, db)

# Mismo permiso que crear escenas: Administrador (1001) y Director
# (1002) arman el contenedor del desglose; el resto de roles solo lo
# consulta (y, en /breakdown/items, ve el desglose general por
# categoría de cada escena) — resuelto dentro del proyecto al que dice
# pertenecer el desglose.
@router.post("/breakdown-sheets")
def store_breakdown_sheet(sheet: BreakdownSheetSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, sheet.id_project, "create_scenes")
    return create_breakdown_sheet(sheet, db)

@router.put("/breakdown-sheets/{id}")
def edit_breakdown_sheet(
    id: str,
    sheet: BreakdownSheetSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=BreakdownSheet, pk_column="id_desglose", not_found_message="Desglose no encontrado",
    )),
):
    return update_breakdown_sheet_full(id, sheet, db)

@router.patch("/breakdown-sheets/{id}")
def patch_breakdown_sheet(
    id: str,
    sheet: BreakdownSheetUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=BreakdownSheet, pk_column="id_desglose", not_found_message="Desglose no encontrado",
    )),
):
    return update_breakdown_sheet(id, sheet, db)

@router.delete("/breakdown-sheets/{id}")
def destroy_breakdown_sheet(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=BreakdownSheet, pk_column="id_desglose", not_found_message="Desglose no encontrado",
    )),
):
    return delete_breakdown_sheet(id, db)
