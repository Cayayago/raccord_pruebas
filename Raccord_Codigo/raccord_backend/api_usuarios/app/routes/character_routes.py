from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.character_controller import (
    get_characters,
    get_character,
    create_character,
    update_character_full,
    update_character,
    delete_character
)
from app.schemas.character_schema import CharacterSchema, CharacterUpdateSchema
from app.models.character_model import Character

# 🔐 autenticación / permisos — resueltos SIEMPRE por proyecto (nunca
# por el id_rol global del JWT), ver app/utils/project_scope.py.
from app.middleware.auth import get_current_user
from app.utils.project_scope import (
    require_project_member,
    require_record_project_permission,
    check_project_permission,
)
from app.utils.module_access import check_module_view_access

router = APIRouter()


# Listado ahora exige id_project en el path (antes era /characters,
# sin filtro — devolvía los personajes de TODOS los proyectos). Se
# permite a cualquier miembro del proyecto (incluido el rol de solo
# lectura), no solo a quien puede crear.
@router.get("/characters/project/{id_project}")
def characters(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "personajes", current_user.get("id_rol"))
    return get_characters(id_project, db)

@router.get("/characters/{id}")
def character(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Character, pk_column="id_personaje", not_found_message="Personaje no encontrado",
    )),
):
    return get_character(id, db)

# Solo Administrador (1001) y Director (1002) crean/editan/eliminan
# personajes (permiso "create_characters", ya definido en la matriz
# RBAC) — pero el rol se resuelve DENTRO del proyecto al que dice
# pertenecer el personaje (character.id_project), no globalmente.
@router.post("/characters")
def store_character(character: CharacterSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, character.id_project, "create_characters")
    return create_character(character, db)

@router.put("/characters/{id}")
def edit_character(
    id: str,
    character: CharacterSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Character, pk_column="id_personaje", not_found_message="Personaje no encontrado",
    )),
):
    return update_character_full(id, character, db)

@router.patch("/characters/{id}")
def patch_character(
    id: str,
    character: CharacterUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Character, pk_column="id_personaje", not_found_message="Personaje no encontrado",
    )),
):
    return update_character(id, character, db)

@router.delete("/characters/{id}")
def destroy_character(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Character, pk_column="id_personaje", not_found_message="Personaje no encontrado",
    )),
):
    return delete_character(id, db)
