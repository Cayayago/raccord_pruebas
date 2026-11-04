from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.department_controller import (
    get_departments,
    get_department,
    create_department,
    update_department_full,
    update_department,
    delete_department
)
from app.schemas.department_schema import DepartmentSchema, DepartmentUpdateSchema

# 🔐 autenticación / permisos
from app.middleware.auth import get_current_user, require_permission

router = APIRouter()

@router.get("/departments")
def departments(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_departments(db)

@router.get("/departments/{id}")
def department(id: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_department(id, db)

@router.post("/departments")
def store_department(department: DepartmentSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return create_department(department, db)

@router.put("/departments/{id}")
def edit_department(id: str, department: DepartmentSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return update_department_full(id, department, db)

@router.patch("/departments/{id}")
def patch_department(id: str, department: DepartmentUpdateSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return update_department(id, department, db)

@router.delete("/departments/{id}")
def destroy_department(id: str, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return delete_department(id, db)
