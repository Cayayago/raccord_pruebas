from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.role_controller import (
    get_roles,
    get_role,
    create_role,
    update_role_full,
    update_role,
    delete_role
)
from app.schemas.role_schema import RoleSchema, RoleUpdateSchema

# 🔐 autenticación / permisos
from app.middleware.auth import get_current_user, require_permission

router = APIRouter()

@router.get("/roles")
def roles(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_roles(db)

@router.get("/roles/{id}")
def role(id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_role(id, db)

@router.post("/roles")
def store_role(role: RoleSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return create_role(role, db)

@router.put("/roles/{id}")
def edit_role(id: int, role: RoleSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return update_role_full(id, role, db)

@router.patch("/roles/{id}")
def patch_role(id: int, role: RoleUpdateSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return update_role(id, role, db)

@router.delete("/roles/{id}")
def destroy_role(id: int, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return delete_role(id, db)
