from sqlalchemy.orm import Session
from app.models.project_model import Project
from app.schemas.project_schema import ProjectSchema
from app.utils.response import api_response
from app.models.user_model import User
from app.models.user_project_model import UserProject

# GET ALL PROJECTS (del usuario que hace la petición)

# Antes devolvía TODOS los proyectos de TODOS los clientes sin
# filtrar — cualquier usuario autenticado veía el catálogo completo de
# proyectos de otras empresas. Ahora se limita a los proyectos donde el
# usuario tiene una fila en user_projects (a los que fue invitado o que
# creó), sin importar su rol.
def get_projects(id_user: str, db: Session):
    projects = (
        db.query(Project)
        .join(UserProject, UserProject.id_project == Project.id_project)
        .filter(UserProject.id_user == id_user)
        .all()
    )
    projects_list = [
        {
            "id_project": p.id_project,
            "project_name": p.project_name,
            "formato_de_produccion": p.formato_de_produccion,
            "genero": p.genero,
            "sinopsis": p.sinopsis,
            "director": p.director,
            "id_client": p.id_client
        }
        for p in projects
    ]
    return api_response(True, "Lista de proyectos", projects_list)


# GET PROJECT BY ID

def get_project(id: str, db: Session):
    project = db.query(Project).filter(Project.id_project == id).first()

    if not project:
        return api_response(False, "Proyecto no encontrado")

    return api_response(True, "Proyecto encontrado", {
        "id_project": project.id_project,
        "project_name": project.project_name,
        "formato_de_produccion": project.formato_de_produccion,
        "genero": project.genero,
        "sinopsis": project.sinopsis,
        "director": project.director,
        "id_client": project.id_client
    })

# UPDATE PROJECT (PUT)

# NOTA: project.id_client (aunque el schema lo trae) a propósito NO se
# copia acá — permitir cambiarlo movería el proyecto entero a OTRA
# empresa/tenant, evadiendo el aislamiento igual que si se dejara mover
# id_project en los otros módulos.
def update_project_full(id: str, project: ProjectSchema, db: Session):
    project_db = db.query(Project).filter(Project.id_project == id).first()

    if not project_db:
        return api_response(False, "Proyecto no encontrado")

    project_db.project_name = project.project_name
    project_db.formato_de_produccion = project.formato_de_produccion
    project_db.genero = project.genero
    project_db.sinopsis = project.sinopsis
    project_db.director = project.director

    db.commit()
    db.refresh(project_db)

    return api_response(True, "Proyecto actualizado", {
        "id_project": project_db.id_project,
        "project_name": project_db.project_name
    })


# UPDATE PROJECT (PATCH)

# Mismo motivo que en update_project_full: id_client se descarta si
# viene en el body parcial, para que no se pueda mover el proyecto a
# otra empresa/tenant vía PATCH.
def update_project(id: str, project, db: Session):
    project_db = db.query(Project).filter(Project.id_project == id).first()

    if not project_db:
        return api_response(False, "Proyecto no encontrado")

    update_data = project.model_dump(exclude_unset=True)
    update_data.pop("id_client", None)

    for key, value in update_data.items():
        setattr(project_db, key, value)

    db.commit()
    db.refresh(project_db)

    return api_response(True, "Proyecto actualizado", {
        "id_project": project_db.id_project,
        "project_name": project_db.project_name
    })


# DELETE PROJECT

def delete_project(id: str, db: Session):
    project = db.query(Project).filter(Project.id_project == id).first()

    if not project:
        return api_response(False, "Proyecto no encontrado")

    db.delete(project)
    db.commit()

    return api_response(True, "Proyecto eliminado")


# GET PROJECTS BY CLIENT

def get_projects_by_client(id_client: str, db: Session):
    projects = db.query(Project).filter(Project.id_client == id_client).all()
    projects_list = [
        {
            "id_project": p.id_project,
            "project_name": p.project_name,
            "formato_de_produccion": p.formato_de_produccion,
            "genero": p.genero,
            "sinopsis": p.sinopsis,
            "director": p.director,
            "id_client": p.id_client
        }
        for p in projects
    ]
    return api_response(True, "Proyectos del cliente", projects_list)

# CREATE PROJECT

# id_client SIEMPRE se toma del usuario que hace la petición (nunca del
# body, aunque el schema lo traiga) — antes se aceptaba tal cual venía
# en el request, así que un usuario podía crear un proyecto colgado de
# OTRA empresa (con solo adivinar/conocer su UUID). Ver
# app.utils.project_scope.get_user_client.
def create_project(project: ProjectSchema, db: Session, id_client_actor: str):
    # id_project es UUID: si el cliente (ej. app offline) ya generó su
    # propio UUID, se respeta (evita colisiones al sincronizar). Si no
    # viene, se deja que la columna lo autogenere (default=uuid.uuid4 /
    # gen_random_uuid() en la BD) — ya no hay generación manual tipo
    # "proj0001", eso era el esquema viejo de IDs secuenciales.
    project_id = project.id_project.strip() if project.id_project and project.id_project.strip() else None

    if project_id:
        existing = db.query(Project).filter(Project.id_project == project_id).first()
        if existing:
            return api_response(False, "ID de proyecto ya existe", error="DUPLICATE_PROJECT")

    new_project = Project(
        project_name=project.project_name,
        formato_de_produccion=project.formato_de_produccion,
        genero=project.genero,
        sinopsis=project.sinopsis,
        director=project.director,
        id_client=id_client_actor
    )
    if project_id:
        new_project.id_project = project_id

    db.add(new_project)
    db.commit()
    db.refresh(new_project)

    return api_response(True, "Proyecto creado", {
        "id_project": new_project.id_project,
        "project_name": new_project.project_name,
        "id_client": new_project.id_client
    })


# CREATE PROJECT AND LINK USER

# Vincula en user_projects con rol Administrador (1001): quien crea el
# proyecto queda como su primer administrador.
def create_project_and_link(project: ProjectSchema, id_user: str, db: Session, id_client_actor: str):
    result = create_project(project, db, id_client_actor)

    if not result["success"]:
        return result

    user_project = UserProject(
        id_user=id_user,
        id_project=result["data"]["id_project"],
        id_rol=1001
    )
    db.add(user_project)
    db.commit()

    return api_response(True, "Proyecto creado y vinculado al usuario", {
        "id_project": result["data"]["id_project"],
        "project_name": result["data"]["project_name"],
        "id_client": result["data"]["id_client"],
        "id_user": id_user
    })

