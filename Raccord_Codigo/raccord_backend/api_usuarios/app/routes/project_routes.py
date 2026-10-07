from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.project_controller import (
    get_projects,
    get_project,
    create_project,
    update_project_full,
    update_project,
    delete_project,
    get_projects_by_client,
    create_project_and_link
)
from app.schemas.project_schema import ProjectSchema, ProjectUpdateSchema, ProjectCreateSchema

# 🔐 autenticación / permisos. Project SÍ tiene id_project como su
# propia PK en el path (a diferencia de Scene/GalleryPhoto/etc.), así
# que las mutaciones se resuelven directo contra user_projects con
# require_project_member/require_project_permission (path_param="id").
# El límite entre EMPRESAS (id_client) se resuelve aparte con
# get_user_client/require_same_client — ver app/utils/project_scope.py.
from app.middleware.auth import get_current_user, require_permission
from app.utils.project_scope import (
    require_project_member,
    require_project_permission,
    get_user_client,
    require_same_client,
)

router = APIRouter()

# Antes /projects sin filtro devolvía los proyectos de TODOS los
# clientes/empresas. Ahora solo los del propio usuario (via
# user_projects).
@router.get("/projects")
def projects(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_projects(current_user["id_user"], db)

# CREATE PROJECT AND LINK USER
# Solo Administrador (1001) crea proyectos. Director (1002) tiene el
# mismo nivel de acceso que Administrador excepto crear proyectos:
# solo puede elegir entre los ya existentes. id_client SIEMPRE se
# resuelve desde el propio actor (nunca desde el body) — ver
# create_project_and_link en project_controller.py.

@router.post("/projects/create")
def store_and_link(data: ProjectCreateSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("create_project"))):
    project = ProjectSchema(
        project_name=data.project_name,
        formato_de_produccion=data.formato_de_produccion,
        genero=data.genero,
        sinopsis=data.sinopsis,
        director=data.director,
        id_client=data.id_client
    )
    id_client_actor = get_user_client(db, current_user.get("id_user"))
    return create_project_and_link(project, data.id_user, db, id_client_actor)

# GET PROJECTS BY CLIENT — antes cualquier usuario autenticado podía
# pedir el id_client de OTRA empresa y ver su catálogo de proyectos.
@router.get("/projects/client/{id_client}")
def projects_by_client(id_client: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    require_same_client(id_client, current_user, db)
    return get_projects_by_client(id_client, db)

@router.get("/projects/{id}")
def project(id: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member(path_param="id"))):
    return get_project(id, db)

@router.post("/projects")
def store_project(project: ProjectSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("create_project"))):
    id_client_actor = get_user_client(db, current_user.get("id_user"))
    return create_project(project, db, id_client_actor)

@router.put("/projects/{id}")
def edit_project(id: str, project: ProjectSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_project_permission("manage_projects", path_param="id"))):
    return update_project_full(id, project, db)

@router.patch("/projects/{id}")
def patch_project(id: str, project: ProjectUpdateSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_project_permission("manage_projects", path_param="id"))):
    return update_project(id, project, db)

@router.delete("/projects/{id}")
def destroy_project(id: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_permission("manage_projects", path_param="id"))):
    return delete_project(id, db)
