from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.scene_controller import (
    get_scenes,
    get_scene,
    get_scenes_by_script,
    get_scenes_by_rodaje,
    get_scenes_by_desglose,
    create_scene,
    update_scene_full,
    update_scene,
    delete_scene
)
from app.schemas.scene_schema import SceneSchema, SceneUpdateSchema
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.shooting_day_model import ShootingDay
from app.models.breakdown_sheet_model import BreakdownSheet

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py. Scene no tiene columna id_project propia:
# se resuelve subiendo por id_guion -> guiones.id_project.
from app.middleware.auth import get_current_user
from app.utils.project_scope import (
    require_project_member,
    require_record_project_permission,
    check_project_permission,
    resolve_project_of_scene,
)
from app.utils.module_access import check_module_view_access

router = APIRouter()

# Antes /scenes sin filtro devolvía las escenas de TODOS los proyectos.
@router.get("/scenes/project/{id_project}")
def scenes(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "escenas", current_user.get("id_rol"))
    return get_scenes(id_project, db)

@router.get("/scenes/script/{id_guion}")
def scenes_by_script(
    id_guion: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Script, pk_column="id_guion", pk_path_param="id_guion", not_found_message="Guion no encontrado",
    )),
):
    return get_scenes_by_script(id_guion, db)

@router.get("/scenes/rodaje/{id_rodaje}")
def scenes_by_rodaje(
    id_rodaje: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=ShootingDay, pk_column="id_rodaje", pk_path_param="id_rodaje", not_found_message="Día de rodaje no encontrado",
    )),
):
    return get_scenes_by_rodaje(id_rodaje, db)

@router.get("/scenes/desglose/{id_desglose}")
def scenes_by_desglose(
    id_desglose: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=BreakdownSheet, pk_column="id_desglose", pk_path_param="id_desglose", not_found_message="Desglose no encontrado",
    )),
):
    return get_scenes_by_desglose(id_desglose, db)

@router.get("/scenes/{id}")
def scene(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Scene, pk_column="id_escena", resolve_project=resolve_project_of_scene,
        not_found_message="Escena no encontrada",
    )),
):
    return get_scene(id, db)

# Solo Administrador (1001) y Director (1002) crean/editan/eliminan
# escenas — resuelto dentro del proyecto del guion (scene.id_guion) al
# que se quiere agregar la escena.
@router.post("/scenes")
def store_scene(scene: SceneSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if not scene.id_guion:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "id_guion es obligatorio para crear una escena")
    script = db.query(Script).filter(Script.id_guion == scene.id_guion).first()
    if not script:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Guion no encontrado")
    check_project_permission(db, current_user, script.id_project, "create_scenes")
    return create_scene(scene, db)

@router.put("/scenes/{id}")
def edit_scene(
    id: str,
    scene: SceneSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=Scene, pk_column="id_escena", resolve_project=resolve_project_of_scene,
        not_found_message="Escena no encontrada",
    )),
):
    return update_scene_full(id, scene, db)

@router.patch("/scenes/{id}")
def patch_scene(
    id: str,
    scene: SceneUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=Scene, pk_column="id_escena", resolve_project=resolve_project_of_scene,
        not_found_message="Escena no encontrada",
    )),
):
    return update_scene(id, scene, db)

@router.delete("/scenes/{id}")
def destroy_scene(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_scenes", model=Scene, pk_column="id_escena", resolve_project=resolve_project_of_scene,
        not_found_message="Escena no encontrada",
    )),
):
    return delete_scene(id, db)
