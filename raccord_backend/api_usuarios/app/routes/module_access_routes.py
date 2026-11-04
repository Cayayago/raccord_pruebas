from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config.database import get_db

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py. "full_management" (Admin/Director) es el
# único gate para fijar/quitar excepciones; para VER se permite además
# a la propia persona consultar su propio acceso (ej. para que el
# frontend decida qué mostrarle en su propio menú).
from app.middleware.auth import get_current_user
from app.utils.project_scope import check_project_membership, check_project_permission
from app.utils.permissions import has_permission

from app.schemas.module_access_schema import ModuleAccessSetSchema
from app.controllers.module_access_controller import (
    list_module_access,
    set_module_access,
    delete_module_access,
)

router = APIRouter(
    prefix="/projects/{id_project}/users/{id_user}/module-access",
    tags=["Module Access"],
)


def _require_self_or_admin(db: Session, current_user: dict, id_project: str, id_user: str) -> int:
    rol = check_project_membership(db, current_user, id_project)
    if str(current_user.get("id_user")) == str(id_user):
        return rol
    if not has_permission(rol, "full_management"):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes permisos para ver los accesos de otra persona",
        )
    return rol


@router.get("")
def get_module_access(
    id_project: str,
    id_user: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    _require_self_or_admin(db, current_user, id_project, id_user)
    return list_module_access(db, id_project, id_user)


# Solo Administrador (1001) y Director (1002) del proyecto pueden
# personalizar el acceso de otra persona ("full_management").
@router.put("/{modulo}")
def put_module_access(
    id_project: str,
    id_user: str,
    modulo: str,
    data: ModuleAccessSetSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    check_project_permission(db, current_user, id_project, "full_management")
    return set_module_access(db, id_project, id_user, modulo, data.nivel, current_user.get("id_user"))


@router.delete("/{modulo}")
def remove_module_access(
    id_project: str,
    id_user: str,
    modulo: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    check_project_permission(db, current_user, id_project, "full_management")
    return delete_module_access(db, id_project, id_user, modulo)
