from sqlalchemy.orm import Session

from app.models.department_model import Department
from app.models.user_model import User

from app.schemas.department_schema import DepartmentSchema

from app.utils.response import api_response


# ==========================================
# GET ALL DEPARTMENTS
# ==========================================
def get_departments(db: Session):
    departments = db.query(Department).order_by(Department.id_departamento).all()

    departments_list = [
        {
            "id_departamento": d.id_departamento,
            "nombre": d.nombre,
            "ubicacion": d.ubicacion
        }
        for d in departments
    ]

    return api_response(True, "Lista de departamentos", departments_list)


# ==========================================
# GET DEPARTMENT BY ID
# ==========================================
def get_department(id: str, db: Session):
    department = db.query(Department).filter(Department.id_departamento == id).first()

    if not department:
        return api_response(False, "Departamento no encontrado")

    return api_response(True, "Departamento encontrado", {
        "id_departamento": department.id_departamento,
        "nombre": department.nombre,
        "ubicacion": department.ubicacion
    })


# ==========================================
# CREATE DEPARTMENT
# ==========================================
# No se manda id_departamento: lo genera el trigger de la BD.
def create_department(department: DepartmentSchema, db: Session):
    new_department = Department(
        nombre=department.nombre,
        ubicacion=department.ubicacion
    )

    db.add(new_department)
    db.commit()
    db.refresh(new_department)

    return api_response(True, "Departamento creado", {
        "id_departamento": new_department.id_departamento,
        "nombre": new_department.nombre,
        "ubicacion": new_department.ubicacion
    })


# ==========================================
# UPDATE DEPARTMENT (PUT - completo)
# ==========================================
def update_department_full(id: str, department: DepartmentSchema, db: Session):
    department_db = db.query(Department).filter(Department.id_departamento == id).first()

    if not department_db:
        return api_response(False, "Departamento no encontrado")

    department_db.nombre = department.nombre
    department_db.ubicacion = department.ubicacion

    db.commit()
    db.refresh(department_db)

    return api_response(True, "Departamento actualizado", {
        "id_departamento": department_db.id_departamento,
        "nombre": department_db.nombre,
        "ubicacion": department_db.ubicacion
    })


# ==========================================
# UPDATE DEPARTMENT (PATCH - parcial)
# ==========================================
def update_department(id: str, department, db: Session):
    department_db = db.query(Department).filter(Department.id_departamento == id).first()

    if not department_db:
        return api_response(False, "Departamento no encontrado")

    update_data = department.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(department_db, key, value)

    db.commit()
    db.refresh(department_db)

    return api_response(True, "Departamento actualizado", {
        "id_departamento": department_db.id_departamento,
        "nombre": department_db.nombre,
        "ubicacion": department_db.ubicacion
    })


# ==========================================
# DELETE DEPARTMENT
# ==========================================
# En la BD, users.id_departamento tiene FK ON DELETE CASCADE hacia
# departamentos. Eso significa que si se deja borrar sin validar,
# Postgres eliminaría en cascada a TODOS los usuarios de ese
# departamento. Por seguridad, se bloquea la eliminación si todavía
# hay usuarios asignados.
def delete_department(id: str, db: Session):
    department = db.query(Department).filter(Department.id_departamento == id).first()

    if not department:
        return api_response(False, "Departamento no encontrado")

    users_in_department = db.query(User).filter(User.id_departamento == id).count()

    if users_in_department > 0:
        return api_response(
            False,
            f"No se puede eliminar: hay {users_in_department} usuario(s) asignados a este departamento",
            error="DEPARTMENT_IN_USE"
        )

    db.delete(department)
    db.commit()

    return api_response(True, "Departamento eliminado")
