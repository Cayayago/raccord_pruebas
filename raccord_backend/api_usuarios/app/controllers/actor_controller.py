from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.models.actor_model import Actor

from app.schemas.actor_schema import ActorSchema

from app.utils.response import api_response
from app.utils.minio_client import BUCKET_IMAGENES, upload_file, delete_file, download_file

# Mismo criterio que la foto de perfil de usuario (ver
# upload_own_photo en user_controller.py): JPEG/PNG/WEBP, tope de 5MB.
ALLOWED_PHOTO_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_PHOTO_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


# ==========================================
# SERIALIZAR ACTOR
# ==========================================
def _serialize(a: Actor):
    return {
        "id_actor": a.id_actor,
        "nombre": a.nombre,
        "apellido": a.apellido,
        "genero": a.genero,
        "fecha_de_nacimiento": str(a.fecha_de_nacimiento) if a.fecha_de_nacimiento else None,
        "talla_zapatos": a.talla_zapatos,
        "ancho_espalda": a.ancho_espalda,
        "pecho": a.pecho,
        "cintura": a.cintura,
        "cadera": a.cadera,
        "largo_manga": a.largo_manga,
        "largo_pierna": a.largo_pierna,
        "talla_anillo": a.talla_anillo,
        "contorno_cabeza": a.contorno_cabeza,
        "contorno_cuello": a.contorno_cuello,
        "color_cabello": a.color_cabello,
        "textura_cabello": a.textura_cabello,
        "tipo_piel": a.tipo_piel,
        "color_ojos": a.color_ojos,
        "tono_piel": a.tono_piel,
        "alergias": a.alergias,
        "habilidades_especiales": a.habilidades_especiales,
        "restricciones": a.restricciones,
        "comentarios_adicionales": a.comentarios_adicionales,
        "nacionalidad": a.nacionalidad,
        "doble_riesgo": a.doble_riesgo,
        "id_personaje": a.id_personaje,
        "id_project": a.id_project,
        "cedula": a.cedula,
        "direccion": a.direccion,
        "telefono": a.telefono,
        "correo": a.correo,
        "status_confirmacion": a.status_confirmacion,
        "llamados": a.llamados,
        "fechas_tentativas": a.fechas_tentativas,
        "guion_enviado": a.guion_enviado,
        "ensayos": a.ensayos,
        "categoria_cast": a.categoria_cast,
    }


# ==========================================
# GET ALL ACTORS (de UN proyecto)
# ==========================================
# Antes traía TODOS los actores de TODOS los proyectos sin filtro.
def get_actors(id_project: str, db: Session):
    actors = (
        db.query(Actor)
        .filter(Actor.id_project == id_project)
        .order_by(Actor.id_actor)
        .all()
    )
    return api_response(True, "Lista de actores", [_serialize(a) for a in actors])


# ==========================================
# GET ACTOR BY ID
# ==========================================
def get_actor(id: str, db: Session):
    actor = db.query(Actor).filter(Actor.id_actor == id).first()

    if not actor:
        return api_response(False, "Actor no encontrado")

    return api_response(True, "Actor encontrado", _serialize(actor))


# ==========================================
# GET ACTORS BY CHARACTER (PERSONAJE)
# ==========================================
def get_actors_by_character(id_personaje: str, db: Session):
    # No hace falta filtrar por id_project acá: la ruta ya exige (vía
    # require_record_project_permission sobre Character) que el usuario
    # pertenezca al proyecto de ESTE personaje antes de llegar aquí, y
    # actors.id_personaje solo puede apuntar a un personaje que ya
    # quedó resuelto en ese mismo proyecto al crearse.
    actors = db.query(Actor).filter(Actor.id_personaje == id_personaje).order_by(Actor.id_actor).all()
    return api_response(True, "Actores asignados a este personaje", [_serialize(a) for a in actors])


# ==========================================
# CREATE ACTOR
# ==========================================
# No se manda id_actor: lo genera el trigger de la BD (act1, act2, ...).
def create_actor(actor: ActorSchema, db: Session):
    new_actor = Actor(
        nombre=actor.nombre,
        apellido=actor.apellido,
        genero=actor.genero,
        fecha_de_nacimiento=actor.fecha_de_nacimiento,
        talla_zapatos=actor.talla_zapatos,
        ancho_espalda=actor.ancho_espalda,
        pecho=actor.pecho,
        cintura=actor.cintura,
        cadera=actor.cadera,
        largo_manga=actor.largo_manga,
        largo_pierna=actor.largo_pierna,
        talla_anillo=actor.talla_anillo,
        contorno_cabeza=actor.contorno_cabeza,
        contorno_cuello=actor.contorno_cuello,
        color_cabello=actor.color_cabello,
        textura_cabello=actor.textura_cabello,
        tipo_piel=actor.tipo_piel,
        color_ojos=actor.color_ojos,
        tono_piel=actor.tono_piel,
        alergias=actor.alergias,
        habilidades_especiales=actor.habilidades_especiales,
        restricciones=actor.restricciones,
        comentarios_adicionales=actor.comentarios_adicionales,
        nacionalidad=actor.nacionalidad,
        doble_riesgo=actor.doble_riesgo,
        id_personaje=actor.id_personaje,
        id_project=actor.id_project,
        cedula=actor.cedula,
        direccion=actor.direccion,
        telefono=actor.telefono,
        correo=actor.correo,
        status_confirmacion=actor.status_confirmacion,
        llamados=actor.llamados,
        fechas_tentativas=actor.fechas_tentativas,
        guion_enviado=actor.guion_enviado,
        ensayos=actor.ensayos,
        categoria_cast=actor.categoria_cast,
    )

    db.add(new_actor)
    db.commit()
    db.refresh(new_actor)

    return api_response(True, "Actor creado", _serialize(new_actor))


# ==========================================
# UPDATE ACTOR (PUT - completo)
# ==========================================
# NOTA: ActorSchema trae id_project (mismo schema que create), pero a
# propósito NO se copia acá — ver la misma nota en character_controller.py.
def update_actor_full(id: str, actor: ActorSchema, db: Session):
    actor_db = db.query(Actor).filter(Actor.id_actor == id).first()

    if not actor_db:
        return api_response(False, "Actor no encontrado")

    actor_db.nombre = actor.nombre
    actor_db.apellido = actor.apellido
    actor_db.genero = actor.genero
    actor_db.fecha_de_nacimiento = actor.fecha_de_nacimiento
    actor_db.talla_zapatos = actor.talla_zapatos
    actor_db.ancho_espalda = actor.ancho_espalda
    actor_db.pecho = actor.pecho
    actor_db.cintura = actor.cintura
    actor_db.cadera = actor.cadera
    actor_db.largo_manga = actor.largo_manga
    actor_db.largo_pierna = actor.largo_pierna
    actor_db.talla_anillo = actor.talla_anillo
    actor_db.contorno_cabeza = actor.contorno_cabeza
    actor_db.contorno_cuello = actor.contorno_cuello
    actor_db.color_cabello = actor.color_cabello
    actor_db.textura_cabello = actor.textura_cabello
    actor_db.tipo_piel = actor.tipo_piel
    actor_db.color_ojos = actor.color_ojos
    actor_db.tono_piel = actor.tono_piel
    actor_db.alergias = actor.alergias
    actor_db.habilidades_especiales = actor.habilidades_especiales
    actor_db.restricciones = actor.restricciones
    actor_db.comentarios_adicionales = actor.comentarios_adicionales
    actor_db.nacionalidad = actor.nacionalidad
    actor_db.doble_riesgo = actor.doble_riesgo
    actor_db.id_personaje = actor.id_personaje
    actor_db.cedula = actor.cedula
    actor_db.direccion = actor.direccion
    actor_db.telefono = actor.telefono
    actor_db.correo = actor.correo
    actor_db.status_confirmacion = actor.status_confirmacion
    actor_db.llamados = actor.llamados
    actor_db.fechas_tentativas = actor.fechas_tentativas
    actor_db.guion_enviado = actor.guion_enviado
    actor_db.ensayos = actor.ensayos
    actor_db.categoria_cast = actor.categoria_cast

    db.commit()
    db.refresh(actor_db)

    return api_response(True, "Actor actualizado", _serialize(actor_db))


# ==========================================
# UPDATE ACTOR (PATCH - parcial)
# ==========================================
def update_actor(id: str, actor, db: Session):
    actor_db = db.query(Actor).filter(Actor.id_actor == id).first()

    if not actor_db:
        return api_response(False, "Actor no encontrado")

    update_data = actor.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(actor_db, key, value)

    db.commit()
    db.refresh(actor_db)

    return api_response(True, "Actor actualizado", _serialize(actor_db))


# ==========================================
# DELETE ACTOR
# ==========================================
# Nada en el esquema referencia actors.id_actor como llave foránea, así
# que no hay cascada peligrosa que resguardar acá (a diferencia de
# personajes, departamentos, guiones, plan_rodaje y desgloses). Sí hay
# que limpiar sus 2 fotos en MinIO (best-effort, delete_file no tumba
# la operación si falla).
def delete_actor(id: str, db: Session):
    actor = db.query(Actor).filter(Actor.id_actor == id).first()

    if not actor:
        return api_response(False, "Actor no encontrado")

    delete_file(BUCKET_IMAGENES, actor.foto_personaje_key)
    delete_file(BUCKET_IMAGENES, actor.foto_normal_key)

    db.delete(actor)
    db.commit()

    return api_response(True, "Actor eliminado")


# ==========================================
# FOTOS DEL ACTOR (subir / ver) — "en personaje" y "normal"
# ==========================================
# Mismo patrón que la foto de perfil de usuario (ver upload_own_photo /
# get_user_photo en user_controller.py): el binario vive en MinIO
# (bucket "imagenes"), acá solo se guarda la key del objeto. Las dos
# fotos comparten la misma lógica de subida/descarga, parametrizada por
# el nombre de columna (`foto_personaje_key` o `foto_normal_key`) para
# no duplicar el código 2 veces.
async def _upload_actor_photo(id_actor: str, file: UploadFile, db: Session, column: str, etiqueta: str):
    actor_db = db.query(Actor).filter(Actor.id_actor == id_actor).first()

    if not actor_db:
        return api_response(False, "Actor no encontrado", error="ACTOR_NOT_FOUND")

    if file.content_type not in ALLOWED_PHOTO_TYPES:
        return api_response(False, "Solo se permiten imágenes JPEG, PNG o WEBP", error="INVALID_FILE_TYPE")

    contenido = await file.read()

    if not contenido:
        return api_response(False, "El archivo está vacío", error="EMPTY_FILE")

    if len(contenido) > MAX_PHOTO_SIZE_BYTES:
        return api_response(
            False,
            f"El archivo supera el tamaño máximo permitido ({MAX_PHOTO_SIZE_BYTES // (1024 * 1024)} MB)",
            error="FILE_TOO_LARGE"
        )

    object_key = f"actors/{id_actor}_{column}_{file.filename}"
    upload_file(BUCKET_IMAGENES, object_key, contenido, file.content_type)

    key_anterior = getattr(actor_db, column)
    if key_anterior and key_anterior != object_key:
        delete_file(BUCKET_IMAGENES, key_anterior)

    setattr(actor_db, column, object_key)
    db.commit()

    return api_response(True, f"Foto {etiqueta} actualizada")


def _get_actor_photo(id_actor: str, db: Session, column: str, etiqueta: str):
    actor_db = db.query(Actor).filter(Actor.id_actor == id_actor).first()
    object_key = getattr(actor_db, column, None) if actor_db else None

    if not actor_db or not object_key:
        raise HTTPException(status_code=404, detail=f"Este actor todavía no tiene foto {etiqueta}")

    try:
        contenido = download_file(BUCKET_IMAGENES, object_key)
    except Exception:
        raise HTTPException(status_code=404, detail="No se pudo recuperar la foto desde el almacenamiento")

    return Response(content=contenido, media_type="image/jpeg")


async def upload_actor_foto_personaje(id_actor: str, file: UploadFile, db: Session):
    return await _upload_actor_photo(id_actor, file, db, "foto_personaje_key", "en personaje")


def get_actor_foto_personaje(id_actor: str, db: Session):
    return _get_actor_photo(id_actor, db, "foto_personaje_key", "en personaje")


async def upload_actor_foto_normal(id_actor: str, file: UploadFile, db: Session):
    return await _upload_actor_photo(id_actor, file, db, "foto_normal_key", "normal")


def get_actor_foto_normal(id_actor: str, db: Session):
    return _get_actor_photo(id_actor, db, "foto_normal_key", "normal")
