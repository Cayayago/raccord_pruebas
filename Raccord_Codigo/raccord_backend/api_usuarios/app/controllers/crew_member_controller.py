from sqlalchemy.orm import Session

from app.models.crew_member_model import CrewMember
from app.models.department_model import Department

from app.schemas.crew_member_schema import CrewMemberSchema

from app.utils.response import api_response


# ==========================================
# SERIALIZAR PERSONA DEL EQUIPO
# ==========================================
def _serialize(c: CrewMember, departamento: Department | None = None):
    return {
        "id_crew": c.id_crew,
        "nombre": c.nombre,
        "cargo": c.cargo,
        "id_departamento": c.id_departamento,
        "departamento_nombre": departamento.nombre if departamento else None,
        "celular": c.celular,
        "correo": c.correo,
        "notas": c.notas,
        "id_project": c.id_project,
    }


# ==========================================
# GET ALL CREW MEMBERS (de UN proyecto)
# ==========================================
# Antes traía el personal de TODOS los proyectos sin filtro.
def get_crew_members(id_project: str, db: Session):
    rows = (
        db.query(CrewMember, Department)
        .outerjoin(Department, CrewMember.id_departamento == Department.id_departamento)
        .filter(CrewMember.id_project == id_project)
        .order_by(CrewMember.nombre)
        .all()
    )
    return api_response(True, "Personal del proyecto", [_serialize(c, d) for c, d in rows])


# ==========================================
# GET CREW MEMBER BY ID
# ==========================================
def get_crew_member(id: str, db: Session):
    row = (
        db.query(CrewMember, Department)
        .outerjoin(Department, CrewMember.id_departamento == Department.id_departamento)
        .filter(CrewMember.id_crew == id)
        .first()
    )

    if not row:
        return api_response(False, "Persona no encontrada")

    c, d = row
    return api_response(True, "Persona encontrada", _serialize(c, d))


# ==========================================
# CREATE CREW MEMBER
# ==========================================
def create_crew_member(crew: CrewMemberSchema, db: Session):
    new_crew = CrewMember(
        nombre=crew.nombre,
        cargo=crew.cargo,
        id_departamento=crew.id_departamento,
        celular=crew.celular,
        correo=crew.correo,
        notas=crew.notas,
        id_project=crew.id_project,
    )

    db.add(new_crew)
    db.commit()
    db.refresh(new_crew)

    departamento = (
        db.query(Department).filter(Department.id_departamento == new_crew.id_departamento).first()
        if new_crew.id_departamento else None
    )

    return api_response(True, "Persona creada", _serialize(new_crew, departamento))


# ==========================================
# UPDATE CREW MEMBER (PUT - completo)
# ==========================================
# NOTA: CrewMemberSchema trae id_project (mismo schema que create),
# pero a propósito NO se copia acá — ver la misma nota en
# character_controller.py.
def update_crew_member_full(id: str, crew: CrewMemberSchema, db: Session):
    crew_db = db.query(CrewMember).filter(CrewMember.id_crew == id).first()

    if not crew_db:
        return api_response(False, "Persona no encontrada")

    crew_db.nombre = crew.nombre
    crew_db.cargo = crew.cargo
    crew_db.id_departamento = crew.id_departamento
    crew_db.celular = crew.celular
    crew_db.correo = crew.correo
    crew_db.notas = crew.notas

    db.commit()
    db.refresh(crew_db)

    departamento = (
        db.query(Department).filter(Department.id_departamento == crew_db.id_departamento).first()
        if crew_db.id_departamento else None
    )

    return api_response(True, "Persona actualizada", _serialize(crew_db, departamento))


# ==========================================
# UPDATE CREW MEMBER (PATCH - parcial)
# ==========================================
def update_crew_member(id: str, crew, db: Session):
    crew_db = db.query(CrewMember).filter(CrewMember.id_crew == id).first()

    if not crew_db:
        return api_response(False, "Persona no encontrada")

    update_data = crew.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(crew_db, key, value)

    db.commit()
    db.refresh(crew_db)

    departamento = (
        db.query(Department).filter(Department.id_departamento == crew_db.id_departamento).first()
        if crew_db.id_departamento else None
    )

    return api_response(True, "Persona actualizada", _serialize(crew_db, departamento))


# ==========================================
# DELETE CREW MEMBER
# ==========================================
def delete_crew_member(id: str, db: Session):
    crew = db.query(CrewMember).filter(CrewMember.id_crew == id).first()

    if not crew:
        return api_response(False, "Persona no encontrada")

    db.delete(crew)
    db.commit()

    return api_response(True, "Persona eliminada")
