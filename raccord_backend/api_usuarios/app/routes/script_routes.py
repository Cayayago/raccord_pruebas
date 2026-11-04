from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.script_controller import (
    get_script,
    get_scripts_by_project,
    create_script,
    update_script_full,
    update_script,
    delete_script,
    upload_script_archivo,
    get_script_archivo,
    segmentar_script
)
from app.schemas.script_schema import ScriptSchema, ScriptUpdateSchema, SegmentarScriptSchema
from app.models.script_model import Script

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

# Antes /scripts sin filtro devolvía los guiones de TODOS los
# proyectos — se eliminó ese endpoint.
@router.get("/scripts/project/{id_project}")
def scripts_by_project(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "guion", current_user.get("id_rol"))
    return get_scripts_by_project(id_project, db)

@router.get("/scripts/{id}")
def script(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return get_script(id, db)

# Solo Administrador (1001) y Director (1002) suben/editan/eliminan
# guiones — resuelto dentro del proyecto al que dice pertenecer el
# guion (script.id_project).
@router.post("/scripts")
def store_script(script: ScriptSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, script.id_project, "upload_scripts")
    return create_script(script, db)

@router.put("/scripts/{id}")
def edit_script(
    id: str,
    script: ScriptSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_scripts", model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return update_script_full(id, script, db)

@router.patch("/scripts/{id}")
def patch_script(
    id: str,
    script: ScriptUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_scripts", model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return update_script(id, script, db)

@router.delete("/scripts/{id}")
def destroy_script(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_scripts", model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return delete_script(id, db)


# ==========================================
# PDF real del guión, guardado en la base de datos
# ==========================================
# Subir/reemplazar el PDF: mismo permiso que crear/editar guiones
# (Administrador/Director), resuelto dentro del proyecto del guion.
@router.post("/scripts/{id}/archivo")
async def upload_script_file(
    id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "upload_scripts", model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return await upload_script_archivo(id, file, db)


# Ver/descargar el PDF: cualquier miembro del proyecto (mismo nivel que
# GET /scripts/{id}).
@router.get("/scripts/{id}/archivo")
def download_script_file(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return get_script_archivo(id, db, current_user)


# ==========================================
# SEGMENTACIÓN AUTOMÁTICA POR ESCENAS (heurística, sin IA)
# ==========================================
# Mismo permiso que crear escenas a mano (create_scenes): al final este
# endpoint termina creando filas de Scene, así que debe exigir lo mismo
# que crearlas manualmente en el módulo de Escenas — resuelto dentro
# del proyecto del guion.
@router.post("/scripts/{id}/segmentar")
def segmentar(
    id: str,
    data: SegmentarScriptSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=Script, pk_column="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return segmentar_script(id, data.confirmar, db)
