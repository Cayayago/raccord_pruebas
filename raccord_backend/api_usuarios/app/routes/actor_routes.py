from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.actor_controller import (
    get_actors,
    get_actor,
    get_actors_by_character,
    create_actor,
    update_actor_full,
    update_actor,
    delete_actor,
    upload_actor_foto_personaje,
    get_actor_foto_personaje,
    upload_actor_foto_normal,
    get_actor_foto_normal,
)
from app.schemas.actor_schema import ActorSchema, ActorUpdateSchema
from app.models.actor_model import Actor
from app.models.character_model import Character

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

# Antes /actors sin filtro devolvía los de TODOS los proyectos.
@router.get("/actors/project/{id_project}")
def actors(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "cast", current_user.get("id_rol"))
    return get_actors(id_project, db)

@router.get("/actors/character/{id_personaje}")
def actors_by_character(
    id_personaje: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Character, pk_column="id_personaje", pk_path_param="id_personaje",
        not_found_message="Personaje no encontrado",
    )),
):
    return get_actors_by_character(id_personaje, db)

@router.get("/actors/{id}")
def actor(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return get_actor(id, db)

# Mismo permiso que personajes: Administrador (1001) y Director (1002)
# gestionan el catálogo de actores y su asignación a personajes —
# resuelto dentro del proyecto al que dice pertenecer el actor.
@router.post("/actors")
def store_actor(actor: ActorSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, actor.id_project, "create_characters")
    return create_actor(actor, db)

@router.put("/actors/{id}")
def edit_actor(
    id: str,
    actor: ActorSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return update_actor_full(id, actor, db)

@router.patch("/actors/{id}")
def patch_actor(
    id: str,
    actor: ActorUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return update_actor(id, actor, db)

@router.delete("/actors/{id}")
def destroy_actor(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return delete_actor(id, db)


# ==========================================
# FOTOS DEL ACTOR (en personaje / normal)
# ==========================================
# Subir: mismo permiso que editar la ficha técnica (create_characters).
# Ver: cualquier miembro del proyecto (None), igual que GET /actors/{id}.
@router.post("/actors/{id}/foto-personaje")
async def store_actor_foto_personaje(
    id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return await upload_actor_foto_personaje(id, file, db)

@router.get("/actors/{id}/foto-personaje")
def actor_foto_personaje(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return get_actor_foto_personaje(id, db)

@router.post("/actors/{id}/foto-normal")
async def store_actor_foto_normal(
    id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return await upload_actor_foto_normal(id, file, db)

@router.get("/actors/{id}/foto-normal")
def actor_foto_normal(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Actor, pk_column="id_actor", not_found_message="Actor no encontrado",
    )),
):
    return get_actor_foto_normal(id, db)
