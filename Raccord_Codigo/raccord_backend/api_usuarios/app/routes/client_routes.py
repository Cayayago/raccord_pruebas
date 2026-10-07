from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.client_controller import (
    get_clients,
    get_client,
    create_client,
    update_client_full,
    update_client,
    delete_client
)
from app.schemas.client_schema import ClientSchema, ClientUpdateSchema

# 🔐 autenticación / permisos. Client es la EMPRESA/tenant dueña de los
# proyectos — el límite de aislamiento acá es users.id_client (ver
# app.utils.project_scope.require_same_client), no un proyecto puntual.
from app.middleware.auth import get_current_user, require_permission
from app.utils.project_scope import require_same_client

router = APIRouter()

# Antes /clients sin filtro devolvía TODAS las empresas registradas.
@router.get("/clients")
def clients(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return get_clients(current_user.get("id_user"), db)

@router.get("/clients/{id}")
def client(id: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    require_same_client(id, current_user, db)
    return get_client(id, db)

# Crear un cliente da de alta una EMPRESA NUEVA (onboarding) — no hay
# todavía un id_client propio contra el cual acotar, así que se deja
# igual que antes (solo gate por rol).
@router.post("/clients")
def store_client(client: ClientSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    return create_client(client, db)

@router.put("/clients/{id}")
def edit_client(id: str, client: ClientSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    require_same_client(id, current_user, db)
    return update_client_full(id, client, db)

@router.patch("/clients/{id}")
def patch_client(id: str, client: ClientUpdateSchema, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    require_same_client(id, current_user, db)
    return update_client(id, client, db)

@router.delete("/clients/{id}")
def destroy_client(id: str, db: Session = Depends(get_db), current_user: dict = Depends(require_permission("full_management"))):
    require_same_client(id, current_user, db)
    return delete_client(id, db)
