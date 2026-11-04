import random
import string
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.user_model import User
from app.models.client_model import Client
from app.models.project_model import Project
from app.models.user_project_model import UserProject

from app.utils.hash import hash_password
from app.utils.formatters import format_text
from app.utils.response import api_response
from app.utils.mail import send_invitation_email, send_welcome_email


# ==========================================
# REGISTER (Client + User)
# ==========================================
def register(data, db: Session):
    existing_client = db.query(Client).filter(Client.email == data.email_empresa).first()
    if existing_client:
        return api_response(False, "La empresa ya está registrada", error="DUPLICATE_CLIENT")

    existing_user = db.query(User).filter(User.mail == data.mail).first()
    if existing_user:
        return api_response(False, "El correo del usuario ya está registrado", error="DUPLICATE_USER")

    try:
        new_client = Client(
            document=data.document,
            razon_social=format_text(data.razon_social),
            representante_legal=format_text(data.representante_legal),
            email=data.email_empresa.strip().lower(),
            address=format_text(data.address),
            telephone=data.telephone,
            number_cellphone=data.number_cellphone,
            id_document=data.id_document
        )

        db.add(new_client)
        db.flush()

        hashed_password = hash_password(data.contrasena)

        new_user = User(
            nombre=format_text(data.nombre),
            apellido=format_text(data.apellido),
            identificacion="CC",
            id_identificacion=data.id_document,
            mail=data.mail.strip().lower(),
            msisdn=data.msisdn,
            direccion=format_text(data.address) if data.address else "",
            fecha_de_nacimiento=datetime.now(),
            estado="activo",
            fecha_de_creacion=datetime.now(),
            ultimo_acceso=datetime.now(),
            contrasena=hashed_password,
            id_departamento=None,
            id_client=new_client.id_cliente,
            id_rol=1001
        )

        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        db.refresh(new_client)

        # No debe tumbar el registro si el correo falla (ej. SMTP caído):
        # la cuenta ya quedó creada, el email de bienvenida es solo un
        # extra informativo/de seguridad.
        try:
            send_welcome_email(new_user.mail, new_user.nombre, new_client.razon_social)
        except Exception as mail_error:
            print(f"Error enviando correo de bienvenida a {new_user.mail}: {mail_error}")

        return api_response(True, "Registro exitoso", {
            "id_user": new_user.id_user,
            "nombre": new_user.nombre,
            "apellido": new_user.apellido,
            "mail": new_user.mail,
            "id_cliente": new_client.id_cliente,
            "razon_social": new_client.razon_social
        })

    except Exception as e:
        db.rollback()
        print("Error en registro:", e)
        return api_response(False, "Error al registrar", error=str(e))


# ==========================================
# INVITE USERS
# ==========================================
# `invitados` es una lista de objetos {nombre_completo, mail,
# id_departamento, id_rol} — un elemento para "Invitar persona" (el
# diálogo del formulario), N elementos para "Carga masiva"
# (Excel/CSV/JSON con esas mismas columnas). A diferencia de la versión
# anterior, cada invitado ya trae su nombre y su departamento desde el
# formulario, así que el usuario que se crea queda completo desde el
# inicio (ya no queda como "Pendiente/Pendiente" sin departamento).
def invite_users(invitados: list, id_project: str, id_client: str, db: Session):
    project = db.query(Project).filter(Project.id_project == id_project).first()

    if not project:
        return api_response(False, "Proyecto no encontrado", error="PROJECT_NOT_FOUND")

    usuarios_creados = []
    errores = []

    for invitado in invitados:
        correo = invitado.mail.strip().lower()
        nombre_completo = invitado.nombre_completo.strip()
        partes = nombre_completo.split(" ", 1)
        nombre = partes[0] if partes else nombre_completo
        apellido = partes[1] if len(partes) > 1 else ""

        existing = db.query(User).filter(User.mail == correo).first()

        if existing:
            existing_link = db.query(UserProject).filter(
                UserProject.id_user == existing.id_user,
                UserProject.id_project == id_project
            ).first()

            if existing_link:
                errores.append({
                    "mail": correo,
                    "error": "Usuario ya está en el proyecto"
                })
                continue

            user_project = UserProject(
                id_user=existing.id_user,
                id_project=id_project,
                id_rol=invitado.id_rol
            )
            db.add(user_project)
            db.flush()

            try:
                enviado = send_invitation_email(correo, project.project_name, "Ya tienes cuenta, usa tu contraseña actual")
            except Exception:
                enviado = False

            usuarios_creados.append({
                "id_user": existing.id_user,
                "mail": correo,
                "invitacion_enviada": enviado,
                "usuario_existente": True
            })
            continue

        contrasena_temporal = ''.join(random.choices(
            string.ascii_letters + string.digits, k=10
        ))

        try:
            new_user = User(
                nombre=format_text(nombre) if nombre else "Pendiente",
                apellido=format_text(apellido) if apellido else "Pendiente",
                identificacion="CC",
                id_identificacion=f"TEMP-{correo}",
                mail=correo,
                msisdn="",
                direccion="",
                fecha_de_nacimiento=datetime.now(),
                estado="pendiente",
                fecha_de_creacion=datetime.now(),
                ultimo_acceso=datetime.now(),
                contrasena=hash_password(contrasena_temporal),
                id_departamento=invitado.id_departamento,
                id_client=id_client,
                id_rol=invitado.id_rol
            )

            db.add(new_user)
            db.flush()

            user_project = UserProject(
                id_user=new_user.id_user,
                id_project=id_project,
                id_rol=invitado.id_rol
            )
            db.add(user_project)
            db.flush()

            try:
                enviado = send_invitation_email(correo, project.project_name, contrasena_temporal)
            except Exception as mail_error:
                print(f"Error enviando correo a {correo}: {mail_error}")
                enviado = False

            usuarios_creados.append({
                "id_user": new_user.id_user,
                "mail": correo,
                "invitacion_enviada": enviado,
                "usuario_existente": False
            })

        except Exception as e:
            errores.append({
                "mail": correo,
                "error": str(e)
            })
            continue

    db.commit()

    return api_response(True, "Proceso de invitación completado", {
        "usuarios_creados": usuarios_creados,
        "errores": errores,
        "total_invitados": len(usuarios_creados),
        "total_errores": len(errores)
    })
