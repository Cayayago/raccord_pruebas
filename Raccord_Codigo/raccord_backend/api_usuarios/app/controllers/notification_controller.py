from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.models.notification_model import Notification, NotificationDepartamento, NotificationRead
from app.models.department_model import Department
from app.models.user_model import User

from app.utils.response import api_response
from app.utils.minio_client import BUCKET_IMAGENES, upload_file, download_file
from app.schemas.notification_schema import ALCANCES, ORIGENES

# Misma política de archivos que las fotos de continuidad (ver
# gallery_photo_controller.py): JPEG/PNG/WEBP, 15 MB tope.
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB


def _serialize(n: Notification, db: Session, id_user_actual: str):
    autor = db.query(User).filter(User.id_user == n.id_user_autor).first() if n.id_user_autor else None
    autor_nombre = f"{autor.nombre} {autor.apellido}".strip() if autor else None

    departamentos = []
    if n.tipo_alcance == "especifica":
        departamentos = (
            db.query(Department)
            .join(NotificationDepartamento, NotificationDepartamento.id_departamento == Department.id_departamento)
            .filter(NotificationDepartamento.id_notificacion == n.id_notificacion)
            .order_by(Department.nombre)
            .all()
        )

    leida = (
        db.query(NotificationRead)
        .filter(NotificationRead.id_notificacion == n.id_notificacion, NotificationRead.id_user == id_user_actual)
        .first()
        is not None
    )

    return {
        "id_notificacion": n.id_notificacion,
        "id_project": n.id_project,
        "id_user_autor": n.id_user_autor,
        "autor_nombre": autor_nombre,
        "tipo_alcance": n.tipo_alcance,
        "origen": n.origen,
        "texto": n.texto,
        "tiene_foto": n.foto_key is not None,
        "fecha_creacion": n.fecha_creacion.isoformat() if n.fecha_creacion else None,
        "leida": leida,
        "departamentos": [{"id_departamento": d.id_departamento, "nombre": d.nombre} for d in departamentos],
    }


# ==========================================
# Departamento del usuario actual (para filtrar "especifica" y para el
# selector multi-departamento del frontend, ver department_routes.py
# que ya expone el catálogo completo de GET /departments).
# ==========================================
def _departamento_del_usuario(id_user: str, db: Session):
    user = db.query(User).filter(User.id_user == id_user).first()
    return user.id_departamento if user else None


# ==========================================
# LISTAR (visibles para el usuario actual: generales + específicas de
# SU departamento — un usuario sin departamento asignado solo ve las
# generales)
# ==========================================
def get_notifications_for_user(id_project: str, current_user: dict, db: Session):
    id_user = current_user.get("id_user")
    id_departamento = _departamento_del_usuario(id_user, db)

    query = db.query(Notification).filter(Notification.id_project == id_project)

    if id_departamento is not None:
        ids_especificas_visibles = (
            db.query(NotificationDepartamento.id_notificacion)
            .filter(NotificationDepartamento.id_departamento == id_departamento)
        )
        query = query.filter(
            (Notification.tipo_alcance == "general") | (Notification.id_notificacion.in_(ids_especificas_visibles))
        )
    else:
        query = query.filter(Notification.tipo_alcance == "general")

    notificaciones = query.order_by(Notification.fecha_creacion.desc()).all()

    return api_response(True, "Notificaciones del proyecto", [_serialize(n, db, id_user) for n in notificaciones])


# ==========================================
# CONTADOR DE NO LEÍDAS (para el badge de la campana)
# ==========================================
def get_unread_count(id_project: str, current_user: dict, db: Session):
    id_user = current_user.get("id_user")
    id_departamento = _departamento_del_usuario(id_user, db)

    query = db.query(Notification).filter(Notification.id_project == id_project)

    if id_departamento is not None:
        ids_especificas_visibles = (
            db.query(NotificationDepartamento.id_notificacion)
            .filter(NotificationDepartamento.id_departamento == id_departamento)
        )
        query = query.filter(
            (Notification.tipo_alcance == "general") | (Notification.id_notificacion.in_(ids_especificas_visibles))
        )
    else:
        query = query.filter(Notification.tipo_alcance == "general")

    ids_leidas = db.query(NotificationRead.id_notificacion).filter(NotificationRead.id_user == id_user)
    no_leidas = query.filter(~Notification.id_notificacion.in_(ids_leidas)).count()

    return api_response(True, "No leídas", {"no_leidas": no_leidas})


# ==========================================
# CREAR NOTIFICACIÓN
# ==========================================
# multipart/form-data: la foto (opcional) llega como UploadFile, el
# resto como Form(...) en la ruta — mismo patrón que
# gallery_photo_controller.upload_photo. "departamentos" llega como
# string separado por comas (ids de Department) cuando tipo_alcance es
# "especifica" — tanto Jefe de Departamento como Director pueden elegir
# VARIOS a la vez (pedido explícito del usuario, 2026-09-27).
async def create_notification(
    id_project: str,
    id_user_autor: str,
    tipo_alcance: str,
    departamentos_csv: str | None,
    texto: str,
    origen: str,
    file: UploadFile | None,
    db: Session,
):
    if tipo_alcance not in ALCANCES:
        return api_response(False, "Alcance inválido", error="INVALID_ALCANCE")
    if origen not in ORIGENES:
        return api_response(False, "Origen inválido", error="INVALID_ORIGEN")
    if not texto or not texto.strip():
        return api_response(False, "El texto de la notificación no puede estar vacío", error="EMPTY_TEXT")

    ids_departamentos: list[str] = []
    if tipo_alcance == "especifica":
        ids_departamentos = [x.strip() for x in (departamentos_csv or "").split(",") if x.strip()]
        if not ids_departamentos:
            return api_response(
                False,
                "Elige al menos un departamento para una notificación específica",
                error="NO_DEPARTMENTS",
            )
        encontrados = (
            db.query(Department.id_departamento)
            .filter(Department.id_departamento.in_(ids_departamentos))
            .count()
        )
        if encontrados != len(set(ids_departamentos)):
            return api_response(False, "Alguno de los departamentos elegidos no existe", error="DEPARTMENT_NOT_FOUND")

    # Si viene foto, se valida y se lee UNA sola vez acá (el objeto
    # UploadFile queda vacío después de leerlo) — los bytes se
    # reutilizan más abajo para subirlos a MinIO, ya con el
    # id_notificacion definitivo en la clave del objeto.
    foto_bytes: bytes | None = None
    archivo_nombre: str | None = None
    if file is not None:
        if file.content_type not in ALLOWED_CONTENT_TYPES:
            return api_response(False, "Solo se permiten imágenes JPEG, PNG o WEBP", error="INVALID_FILE_TYPE")
        contenido = await file.read()
        if contenido:
            if len(contenido) > MAX_FILE_SIZE_BYTES:
                return api_response(
                    False,
                    f"El archivo supera el tamaño máximo permitido ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB)",
                    error="FILE_TOO_LARGE",
                )
            foto_bytes = contenido
            archivo_nombre = file.filename or "foto.jpg"

    notif = Notification(
        id_project=id_project,
        id_user_autor=id_user_autor,
        tipo_alcance=tipo_alcance,
        origen=origen,
        texto=texto.strip(),
        foto_nombre=archivo_nombre,
        foto_tipo=file.content_type if (file is not None and foto_bytes is not None) else None,
        foto_tamano=len(foto_bytes) if foto_bytes is not None else None,
    )

    db.add(notif)
    db.flush()  # asigna id_notificacion sin cerrar la transacción

    if foto_bytes is not None:
        object_key = f"notificaciones/{notif.id_notificacion}_{archivo_nombre}"
        upload_file(BUCKET_IMAGENES, object_key, foto_bytes, file.content_type)
        notif.foto_key = object_key

    for id_departamento in set(ids_departamentos):
        db.add(NotificationDepartamento(id_notificacion=notif.id_notificacion, id_departamento=id_departamento))

    # El autor ya "leyó" su propia notificación — no debe contarle como
    # no leída a él mismo en el badge.
    db.add(NotificationRead(id_notificacion=notif.id_notificacion, id_user=id_user_autor))

    db.commit()
    db.refresh(notif)

    return api_response(True, "Notificación publicada", _serialize(notif, db, id_user_autor))


# ==========================================
# MARCAR COMO LEÍDA (por el usuario actual)
# ==========================================
def mark_as_read(id_notificacion: str, id_user: str, db: Session):
    notif = db.query(Notification).filter(Notification.id_notificacion == id_notificacion).first()
    if not notif:
        return api_response(False, "Notificación no encontrada", error="NOTIFICATION_NOT_FOUND")

    ya_leida = (
        db.query(NotificationRead)
        .filter(NotificationRead.id_notificacion == id_notificacion, NotificationRead.id_user == id_user)
        .first()
    )
    if not ya_leida:
        db.add(NotificationRead(id_notificacion=id_notificacion, id_user=id_user))
        db.commit()

    return api_response(True, "Notificación marcada como leída")


# ==========================================
# GET FOTO DE LA NOTIFICACIÓN (visualizar/descargar)
# ==========================================
def get_notification_photo(id_notificacion: str, db: Session):
    notif = db.query(Notification).filter(Notification.id_notificacion == id_notificacion).first()

    if not notif or not notif.foto_key:
        raise HTTPException(status_code=404, detail="Esta notificación no tiene foto")

    try:
        contenido = download_file(BUCKET_IMAGENES, notif.foto_key)
    except Exception:
        raise HTTPException(status_code=404, detail="No se pudo recuperar el archivo desde el almacenamiento")

    return Response(
        content=contenido,
        media_type=notif.foto_tipo,
        headers={"Content-Disposition": f'inline; filename="{notif.foto_nombre}"'},
    )
