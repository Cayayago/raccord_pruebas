from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.crew_member_controller import (
    get_crew_members,
    get_crew_member,
    create_crew_member,
    update_crew_member_full,
    update_crew_member,
    delete_crew_member,
)
from app.schemas.crew_member_schema import CrewMemberSchema, CrewMemberUpdateSchema
from app.models.crew_member_model import CrewMember

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


# Antes /crew sin filtro devolvía el personal de TODOS los proyectos.
@router.get("/crew/project/{id_project}")
def crew_members(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    # Guardia adicional: accesos personalizados por módulo (ver
    # app/utils/module_access.py) — no reemplaza el chequeo de arriba.
    check_module_view_access(db, current_user, id_project, "crew_list", current_user.get("id_rol"))
    return get_crew_members(id_project, db)


@router.get("/crew/{id}")
def crew_member(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=CrewMember, pk_column="id_crew", not_found_message="Persona no encontrada",
    )),
):
    return get_crew_member(id, db)


# Mismo nivel que personajes/actores: solo Administrador (1001) y
# Director (1002) crean/editan/eliminan personal del proyecto
# (permiso "create_characters") — resuelto dentro de ESE proyecto.
@router.post("/crew")
def store_crew_member(crew: CrewMemberSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    check_project_permission(db, current_user, crew.id_project, "create_characters")
    return create_crew_member(crew, db)


@router.put("/crew/{id}")
def edit_crew_member(
    id: str,
    crew: CrewMemberSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=CrewMember, pk_column="id_crew", not_found_message="Persona no encontrada",
    )),
):
    return update_crew_member_full(id, crew, db)


@router.patch("/crew/{id}")
def patch_crew_member(
    id: str,
    crew: CrewMemberUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=CrewMember, pk_column="id_crew", not_found_message="Persona no encontrada",
    )),
):
    return update_crew_member(id, crew, db)


@router.delete("/crew/{id}")
def destroy_crew_member(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "create_characters", model=CrewMember, pk_column="id_crew", not_found_message="Persona no encontrada",
    )),
):
    return delete_crew_member(id, db)
