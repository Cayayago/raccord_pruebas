from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.notification_controller import (
    get_notifications_for_user,
    get_unread_count,
    create_notification,
    mark_as_read,
    get_notification_photo,
)
from app.models.notification_model import Notification

# 🔐 autenticación / permisos — Notification SÍ tiene columna
# id_project propia (a diferencia de GalleryPhoto/Scene), así que no
# hace falta un resolver de cadena para los endpoints que actúan sobre
# una notificación puntual.
from app.utils.project_scope import (
    require_project_member,
    require_project_permission,
    require_record_project_permission,
)

router = APIRouter()


# Ver las notificaciones del proyecto (ya filtradas del lado del
# controller: generales + específicas del departamento del usuario
# actual — ver notification_controller.get_notifications_for_user).
# Cualquier miembro del proyecto puede ver su propia bandeja.
@router.get("/notificaciones/project/{id_project}")
def notifications_by_project(
    id_project: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_member()),
):
    return get_notifications_for_user(id_project, current_user, db)


# Contador de no leídas — para el badge de la campana en el AppBar.
@router.get("/notificaciones/project/{id_project}/no-leidas")
def notifications_unread_count(
    id_project: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_member()),
):
    return get_unread_count(id_project, current_user, db)


# Publicar una notificación: permiso "publish_notifications" (SOLO
# Jefe de Departamento y Director — ver app/utils/permissions.py).
# multipart/form-data: "departamentos" llega como string separado por
# comas (ids de Department) cuando tipo_alcance es "especifica" — se
# puede elegir MÁS DE UNO a la vez (pedido explícito del usuario).
@router.post("/notificaciones/project/{id_project}")
async def store_notification(
    id_project: str,
    tipo_alcance: str = Form("general"),
    departamentos: str | None = Form(None),
    texto: str = Form(...),
    origen: str = Form("manual"),
    file: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_permission("publish_notifications")),
):
    return await create_notification(
        id_project,
        current_user.get("id_user"),
        tipo_alcance,
        departamentos,
        texto,
        origen,
        file,
        db,
    )


# Marcar como leída: cualquier miembro del proyecto dueño de esa
# notificación (no hace falta "publish_notifications" — leer no es
# publicar).
@router.post("/notificaciones/{id_notificacion}/leer")
def read_notification(
    id_notificacion: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Notification, pk_column="id_notificacion", pk_path_param="id_notificacion",
        not_found_message="Notificación no encontrada",
    )),
):
    return mark_as_read(id_notificacion, current_user.get("id_user"), db)


# Ver/descargar la foto de una notificación (si tiene).
@router.get("/notificaciones/{id_notificacion}/foto")
def download_notification_photo(
    id_notificacion: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Notification, pk_column="id_notificacion", pk_path_param="id_notificacion",
        not_found_message="Notificación no encontrada",
    )),
):
    return get_notification_photo(id_notificacion, db)
