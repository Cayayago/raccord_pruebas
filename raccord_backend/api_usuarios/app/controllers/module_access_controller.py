import uuid

from sqlalchemy.orm import Session

from app.models.module_access_model import UserProjectModuleAccess
from app.models.user_project_model import UserProject
from app.utils.module_access import (
    MODULOS,
    NIVELES,
    NIVEL_RANGO,
    get_role_default_level,
    get_effective_module_level,
)
from app.utils.response import api_response


def _get_role_in_project(db: Session, id_user, id_project):
    link = (
        db.query(UserProject)
        .filter(UserProject.id_user == id_user, UserProject.id_project == id_project)
        .first()
    )
    return link.id_rol if link else None


# ==========================================
# LISTAR (los 9 módulos, con nivel de rol + excepción + efectivo)
# ==========================================
def list_module_access(db: Session, id_project: str, id_user: str):
    id_rol = _get_role_in_project(db, id_user, id_project)
    if id_rol is None:
        return api_response(False, "Esa persona no pertenece a este proyecto")

    overrides = {
        o.modulo: o
        for o in (
            db.query(UserProjectModuleAccess)
            .filter(
                UserProjectModuleAccess.id_user == id_user,
                UserProjectModuleAccess.id_project == id_project,
            )
            .all()
        )
    }

    modulos = []
    for modulo, label in MODULOS.items():
        nivel_rol = get_role_default_level(id_rol, modulo)
        override = overrides.get(modulo)
        nivel_efectivo = get_effective_module_level(db, id_user, id_project, modulo, id_rol)
        modulos.append({
            "modulo": modulo,
            "label": label,
            "nivel_rol": nivel_rol,
            "nivel_rol_label": NIVELES[nivel_rol],
            "nivel_excepcion": override.nivel if override else None,
            "es_excepcion": override is not None,
            "nivel_efectivo": nivel_efectivo,
            "nivel_efectivo_label": NIVELES[nivel_efectivo],
        })

    return api_response(True, "Accesos por módulo", {
        "id_user": id_user,
        "id_project": id_project,
        "id_rol": id_rol,
        "modulos": modulos,
    })


# ==========================================
# FIJAR UNA EXCEPCIÓN (solo puede restringir, ver module_access.py)
# ==========================================
def set_module_access(db: Session, id_project: str, id_user: str, modulo: str, nivel: str, actor_id_user):
    if modulo not in MODULOS:
        return api_response(False, "Módulo no reconocido")

    id_rol = _get_role_in_project(db, id_user, id_project)
    if id_rol is None:
        return api_response(False, "Esa persona no pertenece a este proyecto")

    nivel_rol = get_role_default_level(id_rol, modulo)
    if NIVEL_RANGO[nivel] > NIVEL_RANGO[nivel_rol]:
        return api_response(
            False,
            f"No puedes darle a esta persona más acceso del que ya tiene por su rol "
            f"({NIVELES[nivel_rol]}) en el módulo '{MODULOS[modulo]}'. Una excepción solo puede restringir.",
        )

    row = (
        db.query(UserProjectModuleAccess)
        .filter(
            UserProjectModuleAccess.id_user == id_user,
            UserProjectModuleAccess.id_project == id_project,
            UserProjectModuleAccess.modulo == modulo,
        )
        .first()
    )

    if row:
        row.nivel = nivel
        row.id_actualizado_por = actor_id_user
    else:
        row = UserProjectModuleAccess(
            id=uuid.uuid4(),
            id_user=id_user,
            id_project=id_project,
            modulo=modulo,
            nivel=nivel,
            id_actualizado_por=actor_id_user,
        )
        db.add(row)

    db.commit()
    db.refresh(row)

    return api_response(True, f"Acceso a '{MODULOS[modulo]}' actualizado a {NIVELES[nivel]}", {
        "modulo": modulo,
        "nivel_excepcion": row.nivel,
        "nivel_efectivo": row.nivel,
    })


# ==========================================
# ELIMINAR LA EXCEPCIÓN (vuelve al nivel por defecto del rol)
# ==========================================
def delete_module_access(db: Session, id_project: str, id_user: str, modulo: str):
    if modulo not in MODULOS:
        return api_response(False, "Módulo no reconocido")

    row = (
        db.query(UserProjectModuleAccess)
        .filter(
            UserProjectModuleAccess.id_user == id_user,
            UserProjectModuleAccess.id_project == id_project,
            UserProjectModuleAccess.modulo == modulo,
        )
        .first()
    )

    if not row:
        return api_response(False, "No había ninguna excepción configurada para ese módulo")

    db.delete(row)
    db.commit()

    id_rol = _get_role_in_project(db, id_user, id_project)
    nivel_default = get_role_default_level(id_rol, modulo)

    return api_response(True, f"Acceso a '{MODULOS[modulo]}' restablecido al valor de su rol", {
        "modulo": modulo,
        "nivel_efectivo": nivel_default,
    })
