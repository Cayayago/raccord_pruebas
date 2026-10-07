from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.models.user_model import User
from app.models.project_model import Project
from app.models.user_project_model import UserProject

from app.schemas.user_schema import UserSchema

from app.utils.hash import hash_password, verify_password
from app.utils.formatters import format_text
from app.utils.response import api_response
from app.utils.permissions import has_permission, ADMINISTRADOR, JEFE_DEPARTAMENTO
from app.utils.minio_client import BUCKET_PERFILES, upload_file, delete_file, download_file

# Fotos de perfil: mismo criterio que las fotos de continuidad
# (ver gallery_photo_controller.py) — JPEG/PNG/WEBP, tope razonable.
ALLOWED_AVATAR_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_AVATAR_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


# ==========================================
# GET ALL USERS (de la MISMA empresa/cliente que quien pregunta)
# ==========================================
# Antes devolvía TODOS los usuarios de TODOS los clientes de la
# plataforma (nombre, correo, teléfono, identificación de gente de
# OTRAS empresas). Se acota a users.id_client del que hace la
# petición.
def get_users(id_client: str, db: Session):
    users = db.query(User).filter(User.id_client == id_client).all()
    users_list = [
        {
            "id_user": u.id_user,
            "nombre": u.nombre,
            "apellido": u.apellido,
            "identificacion": u.identificacion,
            "id_identificacion": u.id_identificacion,
            "mail": u.mail,
            "msisdn": u.msisdn,
            "direccion": u.direccion,
            "fecha_de_nacimiento": str(u.fecha_de_nacimiento),
            "estado": u.estado,
            "fecha_de_creacion": str(u.fecha_de_creacion),
            "ultimo_acceso": str(u.ultimo_acceso),
            "id_departamento": u.id_departamento,
            "id_rol": u.id_rol
        }
        for u in users
    ]
    return api_response(True, "Lista de usuarios", users_list)


# ==========================================
# GET USER BY ID
# ==========================================
def get_user(id: str, db: Session):
    user = db.query(User).filter(User.id_user == id).first()

    if not user:
        return api_response(False, "Usuario no encontrado")

    return api_response(True, "Usuario encontrado", {
        "id_user": user.id_user,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "identificacion": user.identificacion,
        "id_identificacion": user.id_identificacion,
        "mail": user.mail,
        "msisdn": user.msisdn,
        "direccion": user.direccion,
        "fecha_de_nacimiento": str(user.fecha_de_nacimiento),
        "estado": user.estado,
        "fecha_de_creacion": str(user.fecha_de_creacion),
        "ultimo_acceso": str(user.ultimo_acceso),
        "id_departamento": user.id_departamento,
        "id_rol": user.id_rol
    })


# ==========================================
# CREATE USER
# ==========================================
def create_user(user: UserSchema, db: Session):
    existing = db.query(User).filter(User.mail == user.mail).first()

    if existing:
        return api_response(False, "Correo ya registrado", error="DUPLICATE_EMAIL")

    existing_id = db.query(User).filter(User.id_identificacion == user.id_identificacion).first()

    if existing_id:
        return api_response(False, "Identificacion ya registrada", error="DUPLICATE_ID")

    hashed_password = hash_password(user.contrasena)

    new_user = User(
        nombre=format_text(user.nombre),
        apellido=format_text(user.apellido),
        identificacion=user.identificacion,
        id_identificacion=user.id_identificacion,
        mail=user.mail.strip().lower(),
        msisdn=user.msisdn,
        direccion=format_text(user.direccion),
        fecha_de_nacimiento=user.fecha_de_nacimiento,
        estado=user.estado,
        contrasena=hashed_password,
        id_departamento=user.id_departamento,
        id_rol=user.id_rol
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return api_response(True, "Usuario registrado correctamente", {
        "id_user": new_user.id_user,
        "nombre": new_user.nombre,
        "apellido": new_user.apellido,
        "mail": new_user.mail
    })


# ==========================================
# UPDATE USER (PUT - completo)
# ==========================================
def update_user_full(id: str, user: UserSchema, db: Session):
    user_db = db.query(User).filter(User.id_user == id).first()

    if not user_db:
        return api_response(False, "Usuario no encontrado")

    user_db.nombre = format_text(user.nombre)
    user_db.apellido = format_text(user.apellido)
    user_db.identificacion = user.identificacion
    user_db.id_identificacion = user.id_identificacion
    user_db.mail = user.mail.strip().lower()
    user_db.msisdn = user.msisdn
    user_db.direccion = format_text(user.direccion)
    user_db.fecha_de_nacimiento = user.fecha_de_nacimiento
    user_db.estado = user.estado
    user_db.contrasena = hash_password(user.contrasena)
    user_db.id_departamento = user.id_departamento
    user_db.id_rol = user.id_rol

    db.commit()
    db.refresh(user_db)

    return api_response(True, "Usuario actualizado", {
        "id_user": user_db.id_user,
        "nombre": user_db.nombre,
        "apellido": user_db.apellido,
        "mail": user_db.mail
    })


# ==========================================
# UPDATE USER (PATCH - parcial)
# ==========================================
def update_user(id: str, user, db: Session):
    user_db = db.query(User).filter(User.id_user == id).first()

    if not user_db:
        return api_response(False, "Usuario no encontrado")

    update_data = user.model_dump(exclude_unset=True)

    campos_texto = ["nombre", "apellido", "direccion"]
    campos_lower = ["mail"]

    for key, value in update_data.items():
        if key == "contrasena" and value is not None:
            value = hash_password(value)
        elif key in campos_texto and value is not None:
            value = format_text(value)
        elif key in campos_lower and value is not None:
            value = value.strip().lower()
        setattr(user_db, key, value)

    db.commit()
    db.refresh(user_db)

    return api_response(True, "Usuario actualizado", {
        "id_user": user_db.id_user,
        "nombre": user_db.nombre,
        "apellido": user_db.apellido,
        "mail": user_db.mail
    })


# ==========================================
# DELETE USER
# ==========================================
# Director (1002) tiene el mismo nivel de acceso que Administrador
# (1001), excepto que no puede eliminar usuarios con rol Administrador.
def delete_user(id: str, db: Session, current_user: dict = None):
    user = db.query(User).filter(User.id_user == id).first()

    if not user:
        return api_response(False, "Usuario no encontrado")

    if user.id_rol == ADMINISTRADOR and current_user is not None:
        if not has_permission(current_user.get("id_rol"), "delete_admin_users"):
            return api_response(
                False,
                "No tienes permisos para eliminar un usuario Administrador",
                error="FORBIDDEN"
            )

    db.delete(user)
    db.commit()

    return api_response(True, "Usuario eliminado")


# ==========================================
# GET USERS BY PROJECT
# ==========================================
def get_users_by_project(id_project: str, db: Session):
    user_projects = db.query(User, UserProject.id_rol).join(
        UserProject, User.id_user == UserProject.id_user
    ).filter(UserProject.id_project == id_project).all()

    users_list = [
        {
            "id_user": user.id_user,
            "nombre": user.nombre,
            "apellido": user.apellido,
            "mail": user.mail,
            "msisdn": user.msisdn,
            "estado": user.estado,
            # Faltaba: sin esto, "Roles del Equipo" nunca reflejaba el
            # departamento real del usuario (siempre salía "—" en el
            # frontend, sin importar lo que hubiera en la BD).
            "id_departamento": user.id_departamento,
            "id_rol": rol,
            "id_project": id_project
        }
        for user, rol in user_projects
    ]
    return api_response(True, "Usuarios del proyecto", users_list)


# ==========================================
# GET PROJECTS BY USER
# ==========================================
def get_user_projects(id_user: str, db: Session):
    projects = db.query(Project, UserProject.id_rol).join(
        UserProject, Project.id_project == UserProject.id_project
    ).filter(UserProject.id_user == id_user).all()

    result = [
        {
            "id_project": project.id_project,
            "project_name": project.project_name,
            "formato_de_produccion": project.formato_de_produccion,
            "genero": project.genero,
            "director": project.director,
            "id_client": project.id_client,
            "id_rol": rol
        }
        for project, rol in projects
    ]

    return api_response(True, "Proyectos del usuario", result)


# ==========================================
# AUTO-EDICIÓN DE PERFIL (PATCH /users/me)
# ==========================================
# Siempre opera sobre el propio usuario autenticado (id_user viene del
# JWT, nunca de un parámetro de ruta) — así no hay forma de editar el
# registro de otra persona. El schema (UserProfileUpdateSchema) ya
# excluye mail/id_rol/estado/contrasena; id_departamento sí se recibe
# pero el controller lo ignora salvo Administrador/Director — ver
# comentario en app/schemas/user_schema.py.
def update_own_profile(id_user: str, data, db: Session, id_rol: int = None):
    user_db = db.query(User).filter(User.id_user == id_user).first()

    if not user_db:
        return api_response(False, "Usuario no encontrado")

    update_data = data.model_dump(exclude_unset=True)

    # Solo Administrador (1001) y Director (1002) pueden cambiar su
    # propio departamento desde este endpoint; para el resto de roles
    # se ignora silenciosamente aunque venga en el body (se asigna
    # desde Roles del Equipo, no desde el propio perfil).
    if "id_departamento" in update_data and id_rol not in (1001, 1002):
        update_data.pop("id_departamento")

    campos_texto = ["nombre", "apellido", "direccion"]

    for key, value in update_data.items():
        if key in campos_texto and value is not None:
            value = format_text(value)
        setattr(user_db, key, value)

    db.commit()
    db.refresh(user_db)

    return api_response(True, "Perfil actualizado", {
        "id_user": user_db.id_user,
        "nombre": user_db.nombre,
        "apellido": user_db.apellido,
    })


# ==========================================
# CAMBIO DE CONTRASEÑA (usuario autenticado, sobre sí mismo)
# ==========================================
def change_own_password(id_user: str, contrasena_actual: str, nueva_contrasena: str, db: Session):
    user_db = db.query(User).filter(User.id_user == id_user).first()

    if not user_db:
        return api_response(False, "Usuario no encontrado")

    if not verify_password(contrasena_actual, user_db.contrasena):
        return api_response(False, "La contraseña actual no es correcta", error="INVALID_PASSWORD")

    if len(nueva_contrasena) < 8:
        return api_response(False, "La nueva contraseña debe tener al menos 8 caracteres", error="WEAK_PASSWORD")

    user_db.contrasena = hash_password(nueva_contrasena)
    db.commit()

    return api_response(True, "Contraseña actualizada correctamente")


# ==========================================
# SUSPENDER / REACTIVAR (PATCH /users/{id}/estado)
# ==========================================
# Pedido explícito del usuario: Administrador (1001) y Director (1002)
# pueden suspender/reactivar a CUALQUIERA del proyecto ("todo su
# equipo"); Jefe de Departamento (1003) solo a gente de SU PROPIO
# departamento. Suspender NUNCA borra nada — solo cambia `estado` a
# "suspendido", lo que le bloquea el login (ver
# login_controller._validar_credenciales); todo lo que esa persona ya
# haya subido (escenas, fotos, desglose, etc.) queda intacto.
ESTADOS_PERMITIDOS = {"activo", "suspendido"}


def set_user_estado(id_target: str, nuevo_estado: str, actor: dict, db: Session):
    if nuevo_estado not in ESTADOS_PERMITIDOS:
        return api_response(False, "Estado inválido, debe ser 'activo' o 'suspendido'", error="INVALID_ESTADO")

    # Se relee al actor desde la BD (no se confía solo en el JWT) porque
    # su id_departamento puede haber cambiado después de emitido el
    # token, y esa comparación es justo la que decide si puede o no
    # tocar al usuario objetivo.
    actor_user = db.query(User).filter(User.id_user == actor.get("id_user")).first()
    if not actor_user:
        return api_response(False, "Usuario no encontrado", error="USER_NOT_FOUND")

    target = db.query(User).filter(User.id_user == id_target).first()
    if not target:
        return api_response(False, "Usuario no encontrado", error="USER_NOT_FOUND")

    if target.id_user == actor_user.id_user:
        return api_response(False, "No puedes suspender ni reactivar tu propia cuenta", error="CANNOT_SELF_SUSPEND")

    if actor_user.id_rol == JEFE_DEPARTAMENTO:
        if not actor_user.id_departamento or target.id_departamento != actor_user.id_departamento:
            return api_response(
                False,
                "Como Jefe de Departamento solo puedes gestionar a personas de tu propio departamento",
                error="FORBIDDEN_DEPARTMENT"
            )

    # Misma regla que borrar usuarios: Director no puede tocar a un
    # Administrador, solo otro Administrador puede.
    if target.id_rol == ADMINISTRADOR and not has_permission(actor_user.id_rol, "delete_admin_users"):
        return api_response(False, "No tienes permisos para gestionar a un usuario Administrador", error="FORBIDDEN")

    target.estado = nuevo_estado
    db.commit()

    mensaje = "Usuario suspendido correctamente" if nuevo_estado == "suspendido" else "Usuario reactivado correctamente"
    return api_response(True, mensaje, {"id_user": target.id_user, "estado": target.estado})


# ==========================================
# FOTO DE PERFIL (subir / ver)
# ==========================================
# Igual patrón que guiones/fotos de continuidad: el binario se sube a
# MinIO (bucket "perfiles"), acá solo se guarda la ruta del objeto.
# Solo se puede subir la propia foto (id_user siempre viene del JWT).
async def upload_own_photo(id_user: str, file: UploadFile, db: Session):
    user_db = db.query(User).filter(User.id_user == id_user).first()

    if not user_db:
        return api_response(False, "Usuario no encontrado", error="USER_NOT_FOUND")

    if file.content_type not in ALLOWED_AVATAR_TYPES:
        return api_response(False, "Solo se permiten imágenes JPEG, PNG o WEBP", error="INVALID_FILE_TYPE")

    contenido = await file.read()

    if not contenido:
        return api_response(False, "El archivo está vacío", error="EMPTY_FILE")

    if len(contenido) > MAX_AVATAR_SIZE_BYTES:
        return api_response(
            False,
            f"El archivo supera el tamaño máximo permitido ({MAX_AVATAR_SIZE_BYTES // (1024 * 1024)} MB)",
            error="FILE_TOO_LARGE"
        )

    object_key = f"{id_user}_{file.filename}"
    upload_file(BUCKET_PERFILES, object_key, contenido, file.content_type)

    if user_db.foto_perfil_key and user_db.foto_perfil_key != object_key:
        delete_file(BUCKET_PERFILES, user_db.foto_perfil_key)

    user_db.foto_perfil_key = object_key
    db.commit()

    return api_response(True, "Foto de perfil actualizada")


# ==========================================
# GET FOTO DE PERFIL (visualizar)
# ==========================================
# Cualquier usuario autenticado puede ver la foto de perfil de
# cualquier otro (se usa también en listas como Roles del Equipo), pero
# solo el dueño puede subir/reemplazar la suya (ver upload_own_photo).
def get_user_photo(id_user: str, db: Session):
    user_db = db.query(User).filter(User.id_user == id_user).first()

    if not user_db or not user_db.foto_perfil_key:
        raise HTTPException(status_code=404, detail="Este usuario todavía no tiene foto de perfil")

    try:
        contenido = download_file(BUCKET_PERFILES, user_db.foto_perfil_key)
    except Exception:
        raise HTTPException(status_code=404, detail="No se pudo recuperar la foto desde el almacenamiento")

    return Response(content=contenido, media_type="image/jpeg")
