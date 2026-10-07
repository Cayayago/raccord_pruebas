"""
Autorización RESUELTA POR PROYECTO (no por rol global).

CONTEXTO (ver conversación con el usuario): antes, `require_permission`
(app/middleware/auth.py) leía el rol de `current_user["id_rol"]`, que
viene fijo en el JWT desde el login y es un valor GLOBAL en
`users.id_rol`. Eso es incorrecto en un sistema donde una misma
persona puede ser Administrador de SU proyecto y, a la vez, ser
invitada como Onset (u otro rol) al proyecto de alguien más — con el
esquema viejo, su token seguiría diciendo "Administrador" sin importar
en qué proyecto estuviera actuando.

Este módulo resuelve el rol EFECTIVO consultando `user_projects` (la
tabla que sí guarda un rol distinto por cada proyecto al que pertenece
un usuario) en cada request, contra el proyecto real sobre el que se
está actuando — nunca contra el JWT. Además, sirve como la pieza que
GARANTIZA aislamiento de datos: si el usuario no tiene ninguna fila en
`user_projects` para ese proyecto, no pasa, sin importar qué tan
"administrador" sea en otro lado.

Cómo se resuelve "el proyecto real sobre el que se está actuando",
según el tipo de ruta:

1. Rutas de LISTADO por proyecto (`/characters/project/{id_project}`,
   etc.): el id_project viene directo en el path -> `require_project_member`
   / `require_project_permission`.

2. Rutas sobre UN registro ya existente (`PUT /characters/{id}`, etc.):
   no basta con un permiso de rol — hay que verificar que ESE registro
   puntual (buscado en la BD) pertenece al proyecto donde el usuario
   tiene el permiso. Ver `require_record_project_permission`. Esto es
   lo que cierra el hueco real de que, aunque alguien "adivine" o
   reutilice el UUID de un registro de OTRO proyecto, igual lo
   rechacemos.

3. Rutas de CREACIÓN (`POST /characters`, etc.): el id_project viene
   en el body ya parseado por Pydantic, así que no hace falta un
   Depends adicional — el controller llama directo a
   `check_project_permission(db, current_user, body.id_project, "...")`
   como primera línea, antes de crear nada.
"""
from typing import Callable, Optional

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config.database import get_db
from app.middleware.auth import get_current_user
from app.models.user_project_model import UserProject
from app.models.scene_model import Scene
from app.models.script_model import Script
from app.utils.permissions import has_permission


# ==========================================
# NÚCLEO: cliente (tenant/empresa) del usuario actual
# ==========================================
# users.id_client (ver user_model.py) es el límite de aislamiento entre
# EMPRESAS distintas usando la plataforma — separado del aislamiento
# por PROYECTO de más arriba. Se usa para /clients, /users y /projects
# (ver project_controller.py, client_controller.py, user_controller.py):
# nadie debe poder ver/editar usuarios, el registro del cliente, o
# enumerar proyectos de OTRA empresa, sin importar su rol.
def get_user_client(db: Session, id_user) -> Optional[str]:
    from app.models.user_model import User  # import local: evita ciclo con user_model -> ...
    user = db.query(User).filter(User.id_user == id_user).first()
    return str(user.id_client) if user and user.id_client else None


def require_same_client(id_client_objetivo, current_user: dict, db: Session):
    """Lanza 403 si el id_client objetivo no es el mismo del usuario
    autenticado (aislamiento entre empresas/tenants)."""
    propio = get_user_client(db, current_user.get("id_user"))
    if not propio or str(id_client_objetivo) != propio:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes acceso a la información de otra empresa/cliente",
        )
    return propio


def require_same_client_user(pk_path_param: str = "id"):
    """Dependencia para rutas de /users/{id}: exige que el usuario
    objetivo pertenezca a la MISMA empresa/cliente que quien hace la
    petición (aislamiento entre tenants) — antes cualquier usuario
    autenticado podía ver/editar el registro de un usuario de OTRA
    empresa con solo conocer/adivinar su UUID."""
    def wrapper(
        request: Request,
        db: Session = Depends(get_db),
        current_user: dict = Depends(get_current_user),
    ):
        from app.models.user_model import User  # import local: evita ciclo

        pk_value = request.path_params.get(pk_path_param)
        target = db.query(User).filter(User.id_user == pk_value).first()
        if not target:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuario no encontrado")
        require_same_client(target.id_client, current_user, db)
        return current_user
    return wrapper


# ==========================================
# NÚCLEO: rol efectivo de un usuario en un proyecto puntual
# ==========================================
def get_role_in_project(db: Session, id_user, id_project) -> Optional[int]:
    if not id_user or not id_project:
        return None
    link = (
        db.query(UserProject)
        .filter(UserProject.id_user == id_user, UserProject.id_project == id_project)
        .first()
    )
    return link.id_rol if link else None


# ==========================================
# HELPERS PLANOS (para usar DENTRO de un controller, ej. en creación,
# donde el id_project viene del body y no tiene sentido un Depends)
# ==========================================
def check_project_membership(db: Session, current_user: dict, id_project) -> int:
    """Verifica que el usuario pertenezca al proyecto (cualquier rol).
    Devuelve el id_rol efectivo o lanza 403."""
    rol = get_role_in_project(db, current_user.get("id_user"), id_project)
    if rol is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No perteneces a este proyecto",
        )
    return rol


def check_project_permission(db: Session, current_user: dict, id_project, permission: str) -> int:
    """Igual que check_project_membership, pero además exige el
    permiso puntual dentro de ESE proyecto."""
    rol = check_project_membership(db, current_user, id_project)
    if not has_permission(rol, permission):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "No tienes permisos para realizar esta acción",
        )
    return rol


# ==========================================
# DEPENDENCIAS FASTAPI — caso 1: id_project directo en el path
# ==========================================
def require_project_member(path_param: str = "id_project"):
    """Exige pertenecer al proyecto del path, sin importar el rol —
    para endpoints de solo lectura (listar/ver), donde incluso el rol
    'Usuario' (solo lectura) debe poder entrar."""
    def wrapper(
        request: Request,
        db: Session = Depends(get_db),
        current_user: dict = Depends(get_current_user),
    ):
        id_project = request.path_params.get(path_param)
        if not id_project:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Falta {path_param} en la ruta")
        rol = check_project_membership(db, current_user, id_project)
        return {**current_user, "id_rol": rol, "id_project": id_project}
    return wrapper


def require_project_permission(permission: str, path_param: str = "id_project"):
    """Como require_project_member, pero además exige el permiso
    puntual — para mutaciones cuyo id_project ya viene directo en el
    path (ej. PUT /projects/{id}, donde `id` ES el proyecto)."""
    def wrapper(
        request: Request,
        db: Session = Depends(get_db),
        current_user: dict = Depends(get_current_user),
    ):
        id_project = request.path_params.get(path_param)
        if not id_project:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Falta {path_param} en la ruta")
        rol = check_project_permission(db, current_user, id_project, permission)
        return {**current_user, "id_rol": rol, "id_project": id_project}
    return wrapper


# ==========================================
# DEPENDENCIAS FASTAPI — caso 2: resolver el proyecto de UN registro
# existente (por su propia llave primaria en el path)
# ==========================================
def require_record_project_permission(
    permission: Optional[str],
    *,
    model,
    pk_column: str,
    pk_path_param: str = "id",
    resolve_project: Optional[Callable] = None,
    not_found_message: str = "Registro no encontrado",
):
    """
    - model / pk_column: para buscar el registro (`db.query(model).filter(getattr(model, pk_column) == valor)`).
    - resolve_project(record, db) -> id_project. Si no se pasa, se usa
      `record.id_project` directo (los 5 modelos con columna propia:
      Character, Actor, CrewMember, ShootingDay, BreakdownSheet).
      Para modelos sin columna propia (Scene, DesgloseItem,
      GalleryPhoto, SceneCharacter) hay que pasar un resolver que suba
      por la cadena de relaciones — ver `resolve_project_of_scene` y
      compañía más abajo.
    - permission=None: solo exige pertenecer al proyecto del registro
      (para lecturas), sin exigir un permiso puntual.
    """
    def _resolve(record, db):
        if resolve_project is not None:
            return resolve_project(record, db)
        return getattr(record, "id_project", None)

    def wrapper(
        request: Request,
        db: Session = Depends(get_db),
        current_user: dict = Depends(get_current_user),
    ):
        pk_value = request.path_params.get(pk_path_param)
        record = db.query(model).filter(getattr(model, pk_column) == pk_value).first()
        if not record:
            raise HTTPException(status.HTTP_404_NOT_FOUND, not_found_message)

        id_project = _resolve(record, db)
        if not id_project:
            # Fila todavía no migrada (ver scripts/backfill_project_scoping.py)
            # o registro genuinamente sin proyecto resoluble.
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Este registro todavía no tiene un proyecto asignado. "
                "Contacta a un administrador para completarlo.",
            )

        if permission is None:
            rol = check_project_membership(db, current_user, id_project)
        else:
            rol = check_project_permission(db, current_user, id_project, permission)

        return {**current_user, "id_rol": rol, "id_project": str(id_project)}
    return wrapper


# ==========================================
# RESOLVERS DE CADENA (para modelos sin columna id_project propia)
# ==========================================
def resolve_project_of_scene(scene, db: Session):
    if scene is None or scene.id_guion is None:
        return None
    script = db.query(Script).filter(Script.id_guion == scene.id_guion).first()
    return script.id_project if script else None


def resolve_project_via_scene_fk(scene_fk_attr: str):
    """Para modelos que traen `id_escena` (DesgloseItem, GalleryPhoto,
    SceneCharacter): sube escena -> guion -> proyecto."""
    def resolver(record, db: Session):
        id_escena = getattr(record, scene_fk_attr, None)
        if id_escena is None:
            return None
        scene = db.query(Scene).filter(Scene.id_escena == id_escena).first()
        return resolve_project_of_scene(scene, db)
    return resolver


def resolve_project_via_desglose_item(detalle, db: Session):
    """Para DesgloseItemDetalle (la segmentación por departamento): sube
    detalle -> desglose_item -> escena -> guion -> proyecto. Import
    local para evitar un ciclo con app.models.breakdown_model."""
    from app.models.breakdown_model import DesgloseItem

    if detalle is None or detalle.id_desglose_item is None:
        return None
    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == detalle.id_desglose_item).first()
    if item is None or item.id_escena is None:
        return None
    scene = db.query(Scene).filter(Scene.id_escena == item.id_escena).first()
    return resolve_project_of_scene(scene, db)
