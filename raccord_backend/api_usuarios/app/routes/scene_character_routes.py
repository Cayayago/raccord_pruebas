from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.scene_character_controller import (
    get_cast_by_scene,
    add_character_to_scene,
    remove_character_from_scene
)
from app.schemas.scene_character_schema import SceneCharacterSchema
from app.models.scene_model import Scene

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py. Scene no tiene columna id_project propia:
# se resuelve subiendo por id_guion -> guiones.id_project.
from app.utils.project_scope import require_record_project_permission, resolve_project_of_scene

router = APIRouter()

@router.get("/scenes/{id_escena}/cast")
def cast_by_scene(
    id_escena: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return get_cast_by_scene(id_escena, db)

# Mismo permiso que crear personajes/escenas: Administrador (1001) y
# Director (1002) arman el cast de cada escena — resuelto dentro del
# proyecto de la escena.
@router.post("/scenes/{id_escena}/cast")
def store_cast(
    id_escena: str,
    data: SceneCharacterSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return add_character_to_scene(id_escena, data, db)

@router.delete("/scenes/{id_escena}/cast/{id_personaje}")
def destroy_cast(
    id_escena: str,
    id_personaje: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return remove_character_from_scene(id_escena, id_personaje, db)
