"""
Accesos personalizados por módulo — capa liviana ENCIMA del sistema de
roles existente (app/utils/permissions.py), NO un reemplazo.

CONTEXTO (evaluado y acordado con el usuario): se consideró migrar a
un esquema completo de 3 capas (rol cinematográfico + rol base +
matriz de permisos por módulo con excepciones por persona, al estilo
Notion/Asana), pero se descartó por ser una reconstrucción enorme no
justificada por la necesidad actual (los 5 roles fijos cubren casi
todos los casos reales). En su lugar se acordó esta versión liviana:

- El rol (user_projects.id_rol) sigue siendo la base — decide el nivel
  POR DEFECTO de cada persona en cada módulo (ver ROLE_MODULE_LEVELS).
- Administrador/Director de un proyecto pueden, puntualmente, bajarle
  el nivel a UNA persona en UN módulo (tabla
  user_project_module_access, ver sql/021_module_access_overrides.sql)
  — caso más pedido: restringir un módulo sensible para alguien
  concreto sin crear un rol nuevo ni afectar a nadie más.
- La excepción SOLO PUEDE RESTRINGIR, nunca ampliar lo que el rol ya
  permite (ver get_effective_module_level) — así no hay riesgo de que
  alguien se autoasigne más acceso del que su rol le daría, y no hace
  falta tocar ninguna de las verificaciones de permiso existentes
  (require_permission / check_project_permission) para las
  operaciones de escritura: esas siguen mandando igual que siempre.
  Lo que esta capa agrega es la posibilidad de OCULTAR/BLOQUEAR un
  módulo completo para una persona puntual (nivel "sin_acceso"),
  aplicado como guardia adicional en el listado principal de cada
  módulo — ver check_module_view_access más abajo y su uso en las
  rutas de cada módulo.
"""
from typing import Optional

from sqlalchemy.orm import Session

from app.models.module_access_model import UserProjectModuleAccess
from app.utils.permissions import ADMINISTRADOR, DIRECTOR, JEFE_DEPARTAMENTO, ONSET, USUARIO


# ==========================================
# CATÁLOGO DE MÓDULOS
# ==========================================
# Debe reflejar los 9 módulos reales del menú (ver appSideMenuItems en
# raccord_flutter/lib/widgets/app_scaffold.dart). La clave (izquierda)
# es la que se guarda en `modulo`; el valor es solo la etiqueta legible
# para el frontend/diálogo de "Personalizar accesos".
MODULOS = {
    "guion": "Guión",
    "escenas": "Escenas",
    "desglose": "Desglose",
    "plan_rodaje": "Plan de Rodaje",
    "personajes": "Personajes",
    "cast": "Cast List",
    "galeria": "Galería",
    "crew_list": "Crew List",
    "roles": "Roles",
}


# ==========================================
# CATÁLOGO DE NIVELES (orden = jerarquía)
# ==========================================
NIVELES = {
    "sin_acceso": "Sin acceso",
    "ver": "Ver",
    "comentar": "Comentar",
    "editar": "Editar",
    "administrar": "Administrar",
}

# Rango numérico para poder comparar "¿nivel A es mayor o igual a B?".
NIVEL_RANGO = {
    "sin_acceso": 0,
    "ver": 1,
    "comentar": 2,
    "editar": 3,
    "administrar": 4,
}


def nivel_valido(nivel: str) -> bool:
    return nivel in NIVEL_RANGO


# ==========================================
# NIVEL POR DEFECTO DE CADA ROL EN CADA MÓDULO
# ==========================================
# Resumen derivado de ROLE_PERMISSIONS (app/utils/permissions.py) para
# poder mostrar/comparar un único nivel por módulo en el diálogo de
# accesos — es una SIMPLIFICACIÓN con fines de UI y de tope máximo de
# la excepción; la autorización real de cada operación de escritura
# sigue viviendo en los permisos booleanos existentes de cada ruta.
#
# Criterio usado por módulo:
# - guion: "upload_scripts" -> administrar (Admin/Director suben,
#   editan y eliminan guiones); "download_files" sin "upload_scripts"
#   -> ver (puede consultar/descargar, no modificar).
# - escenas: "create_scenes" -> administrar; "comment_scenes" sin
#   "create_scenes" -> comentar (Onset comenta escenas); resto -> ver.
# - desglose: "manage_general_breakdown" -> administrar (desglose
#   general completo); "edit_department_breakdown" -> editar (solo la
#   segmentación de su propio departamento, el filtro real vive en el
#   controller); "view_department_breakdown" -> ver; resto -> ver.
# - plan_rodaje: solo Admin/Director administran (no hay un permiso
#   booleano dedicado; se asimila a "manage_projects"); el resto ve.
# - personajes / cast: "create_characters" -> administrar; resto -> ver.
# - galeria: "upload_photos" + "delete_photos" -> administrar;
#   "upload_photos" sin "delete_photos" -> comentar (puede aportar
#   fotos pero no borrar las de otros, caso de Onset); resto -> ver.
# - crew_list: mismo criterio que personajes ("create_characters"
#   gatilla también el CRUD de personal_produccion, ver
#   crew_member_routes.py).
# - roles: "full_management" -> administrar (CRUD del catálogo de
#   roles); "invite_users" sin "full_management" -> editar (Jefe de
#   Departamento invita gente y gestiona estado, pero no toca el
#   catálogo); sin "invite_users" -> sin_acceso (coincide con que hoy
#   el menú ya oculta "/roles" si no tiene ese permiso).
ROLE_MODULE_LEVELS = {
    ADMINISTRADOR: {m: "administrar" for m in MODULOS},
    DIRECTOR: {m: "administrar" for m in MODULOS},
    JEFE_DEPARTAMENTO: {
        "guion": "ver",
        "escenas": "ver",
        "desglose": "editar",
        "plan_rodaje": "ver",
        "personajes": "ver",
        "cast": "ver",
        "galeria": "administrar",
        "crew_list": "ver",
        "roles": "editar",
    },
    ONSET: {
        "guion": "ver",
        "escenas": "comentar",
        "desglose": "ver",
        "plan_rodaje": "ver",
        "personajes": "ver",
        "cast": "ver",
        "galeria": "comentar",
        "crew_list": "ver",
        "roles": "sin_acceso",
    },
    USUARIO: {
        "guion": "ver",
        "escenas": "ver",
        "desglose": "ver",
        "plan_rodaje": "ver",
        "personajes": "ver",
        "cast": "ver",
        "galeria": "ver",
        "crew_list": "ver",
        "roles": "sin_acceso",
    },
}


def get_role_default_level(id_rol: Optional[int], modulo: str) -> str:
    """Nivel de partida (antes de aplicar cualquier excepción) para un
    rol en un módulo dado. Si el rol o el módulo no se reconocen,
    "sin_acceso" por seguridad (mismo criterio que has_permission)."""
    niveles_rol = ROLE_MODULE_LEVELS.get(id_rol)
    if not niveles_rol:
        return "sin_acceso"
    return niveles_rol.get(modulo, "sin_acceso")


# ==========================================
# NIVEL EFECTIVO (rol + excepción, si existe)
# ==========================================
def get_effective_module_level(db: Session, id_user, id_project, modulo: str, id_rol: Optional[int]) -> str:
    """Nivel real que debe aplicarse: el del rol, salvo que exista una
    excepción en user_project_module_access — y en ese caso, SOLO si es
    más restrictiva (nunca se usa la excepción para dar más acceso del
    que el rol ya otorgaría; ver docstring del módulo)."""
    default_level = get_role_default_level(id_rol, modulo)

    override = (
        db.query(UserProjectModuleAccess)
        .filter(
            UserProjectModuleAccess.id_user == id_user,
            UserProjectModuleAccess.id_project == id_project,
            UserProjectModuleAccess.modulo == modulo,
        )
        .first()
    )
    if not override or not nivel_valido(override.nivel):
        return default_level

    if NIVEL_RANGO[override.nivel] < NIVEL_RANGO[default_level]:
        return override.nivel
    return default_level


def check_module_view_access(db: Session, current_user: dict, id_project, modulo: str, id_rol: Optional[int]):
    """Guardia adicional (aditiva, no reemplaza nada) para el listado
    principal de un módulo: si la persona quedó con nivel "sin_acceso"
    en ESE módulo (por excepción puntual), se le bloquea aunque su rol
    normalmente le permitiría entrar. Se usa junto a
    require_project_member()/require_project_permission(), nunca en su
    lugar."""
    from fastapi import HTTPException, status

    nivel = get_effective_module_level(db, current_user.get("id_user"), id_project, modulo, id_rol)
    if nivel == "sin_acceso":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes acceso a este módulo en este proyecto",
        )


def check_module_view_access_any(db: Session, current_user: dict, id_project, modulos: list[str], id_rol: Optional[int]):
    """Igual que check_module_view_access, pero para endpoints que
    alimentan a MÁS DE UNA pantalla con distintos requisitos de acceso
    (p. ej. GET /users/project/{id} sirve tanto a "Roles del Equipo"
    como a "Crew List"). Basta con tener acceso a UNO de los módulos
    listados en [modulos] para pasar — solo se bloquea si TODOS
    resultan "sin_acceso"."""
    from fastapi import HTTPException, status

    niveles = [
        get_effective_module_level(db, current_user.get("id_user"), id_project, modulo, id_rol)
        for modulo in modulos
    ]
    if all(nivel == "sin_acceso" for nivel in niveles):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes acceso a este módulo en este proyecto",
        )
