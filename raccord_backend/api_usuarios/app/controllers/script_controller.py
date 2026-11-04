import logging

from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy.orm import Session

logger = logging.getLogger("raccord")

from app.models.script_model import Script
from app.models.scene_model import Scene
from app.models.gallery_photo_model import GalleryPhoto
from app.models.character_model import Character
from app.models.scene_character_model import SceneCharacter
from app.models.user_model import User

from app.schemas.script_schema import ScriptSchema

from app.utils.response import api_response
from app.utils.minio_client import BUCKET_GUIONES, BUCKET_IMAGENES, upload_file, delete_file, download_file
from app.utils.watermark import add_watermark
from app.utils.script_parser import parse_script

# Solo guiones en estos 2 estados se pueden segmentar automáticamente
# (pedido explícito del usuario): un guion todavía en Borrador/Revisión
# puede cambiar de contenido antes de rodarse, así que generar escenas
# "de verdad" a partir de una versión que todavía puede cambiar
# generaría trabajo duplicado o escenas desactualizadas.
ESTADOS_SEGMENTABLES = {"Aprobado", "En Rodaje"}

# Solo PDF, y con un tope de tamaño razonable (evita que alguien suba
# un archivo gigante sin querer). El binario se sube al bucket
# "guiones" de MinIO, no a la base de datos.
ALLOWED_CONTENT_TYPES = {"application/pdf"}
MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB


# ==========================================
# GET SCRIPT BY ID
# ==========================================
def get_script(id: str, db: Session):
    script = db.query(Script).filter(Script.id_guion == id).first()

    if not script:
        return api_response(False, "Guion no encontrado")

    return api_response(True, "Guion encontrado", {
        "id_guion": script.id_guion,
        "numero_de_version": script.numero_de_version,
        "fecha_de_emision": str(script.fecha_de_emision),
        "estado": script.estado,
        "archivo": script.archivo,
        "archivo_nombre": script.archivo_nombre,
        "archivo_tamano": script.archivo_tamano,
        "nombre": script.nombre,
        "descripcion": script.descripcion,
        "id_project": script.id_project
    })


# ==========================================
# GET SCRIPTS BY PROJECT
# ==========================================
# Único listado que existe ahora (antes también había un GET /scripts
# sin filtro que devolvía los guiones de TODOS los proyectos — se
# eliminó).
def get_scripts_by_project(id_project: str, db: Session):
    scripts = db.query(Script).filter(Script.id_project == id_project).order_by(Script.id_guion).all()

    scripts_list = [
        {
            "id_guion": s.id_guion,
            "numero_de_version": s.numero_de_version,
            "fecha_de_emision": str(s.fecha_de_emision),
            "estado": s.estado,
            "archivo": s.archivo,
            "archivo_nombre": s.archivo_nombre,
            "archivo_tamano": s.archivo_tamano,
            "nombre": s.nombre,
            "descripcion": s.descripcion,
            "id_project": s.id_project
        }
        for s in scripts
    ]

    return api_response(True, "Guiones del proyecto", scripts_list)


# ==========================================
# CREATE SCRIPT
# ==========================================
def create_script(script: ScriptSchema, db: Session):
    # BUGFIX: antes comparaba numero_de_version contra TODOS los
    # guiones de la base de datos, sin filtrar por id_project — un V2
    # ya usado en el proyecto de otra persona bloqueaba crear un V2
    # acá, aunque este proyecto no tuviera ninguno. La versión solo
    # tiene que ser única DENTRO del mismo proyecto.
    existing = db.query(Script).filter(
        Script.numero_de_version == script.numero_de_version,
        Script.id_project == script.id_project,
    ).first()

    if existing:
        return api_response(False, "Ya existe un guion con ese número de versión", error="DUPLICATE_VERSION")

    new_script = Script(
        numero_de_version=script.numero_de_version,
        fecha_de_emision=script.fecha_de_emision,
        estado=script.estado,
        archivo=script.archivo,
        nombre=script.nombre,
        descripcion=script.descripcion,
        id_project=script.id_project
    )

    db.add(new_script)
    db.commit()
    db.refresh(new_script)

    return api_response(True, "Guion creado", {
        "id_guion": new_script.id_guion,
        "numero_de_version": new_script.numero_de_version,
        "nombre": new_script.nombre,
        "id_project": new_script.id_project
    })


# ==========================================
# UPDATE SCRIPT (PUT - completo)
# ==========================================
def update_script_full(id: str, script: ScriptSchema, db: Session):
    script_db = db.query(Script).filter(Script.id_guion == id).first()

    if not script_db:
        return api_response(False, "Guion no encontrado")

    # BUGFIX: mismo caso que en create_script — la unicidad de versión
    # es POR PROYECTO, no global.
    version_exists = db.query(Script).filter(
        Script.numero_de_version == script.numero_de_version,
        Script.id_project == script.id_project,
        Script.id_guion != id
    ).first()

    if version_exists:
        return api_response(False, "Ya existe otro guion con ese número de versión", error="DUPLICATE_VERSION")

    script_db.numero_de_version = script.numero_de_version
    script_db.fecha_de_emision = script.fecha_de_emision
    script_db.estado = script.estado
    script_db.archivo = script.archivo
    script_db.nombre = script.nombre
    script_db.descripcion = script.descripcion
    script_db.id_project = script.id_project

    db.commit()
    db.refresh(script_db)

    return api_response(True, "Guion actualizado", {
        "id_guion": script_db.id_guion,
        "numero_de_version": script_db.numero_de_version,
        "nombre": script_db.nombre
    })


# ==========================================
# UPDATE SCRIPT (PATCH - parcial)
# ==========================================
def update_script(id: str, script, db: Session):
    script_db = db.query(Script).filter(Script.id_guion == id).first()

    if not script_db:
        return api_response(False, "Guion no encontrado")

    update_data = script.model_dump(exclude_unset=True)

    if "numero_de_version" in update_data:
        # BUGFIX: mismo caso que en create_script — la unicidad de
        # versión es POR PROYECTO, no global. Se usa
        # update_data.get("id_project") si el propio PATCH también
        # está moviendo el guion de proyecto, si no el proyecto actual
        # del guion (script_db.id_project) — nunca "cualquier proyecto".
        version_exists = db.query(Script).filter(
            Script.numero_de_version == update_data["numero_de_version"],
            Script.id_project == update_data.get("id_project", script_db.id_project),
            Script.id_guion != id
        ).first()

        if version_exists:
            return api_response(False, "Ya existe otro guion con ese número de versión", error="DUPLICATE_VERSION")

    for key, value in update_data.items():
        setattr(script_db, key, value)

    db.commit()
    db.refresh(script_db)

    return api_response(True, "Guion actualizado", {
        "id_guion": script_db.id_guion,
        "numero_de_version": script_db.numero_de_version,
        "nombre": script_db.nombre
    })


# ==========================================
# DELETE SCRIPT (borrado en cascada)
# ==========================================
# CAMBIO DE COMPORTAMIENTO A PROPÓSITO (antes bloqueaba el borrado si
# el guion tenía escenas asociadas): ahora se borra TODO en cascada —
# escenas, desglose, fotos de continuidad y vínculos con personajes de
# ese guion — sin posibilidad de deshacerlo. El frontend muestra un
# diálogo de confirmación explícito antes de llamar este endpoint (ver
# confirmDelete() en scripts_screen.dart), así que para cuando se llega
# acá la persona ya confirmó que sabe que esto no tiene vuelta atrás.
#
# La cascada en la base de datos ya existe a nivel de FKs
# (fk_escenas_guion, desglose_items_id_escena_fkey,
# fotos_continuidad_id_escena_fkey, fk_escenas_personajes_escena, todas
# ON DELETE CASCADE — ver sql/000_schema_completo.sql), así que basta
# con borrar la fila del guion y Postgres se encarga del resto de las
# tablas. Lo único que Postgres NO sabe limpiar son los binarios en
# MinIO (fotos de continuidad + PDF del guion): esos se recolectan y
# borran ANTES del db.delete(), porque una vez cascadeadas las filas de
# fotos_continuidad ya no hay forma de recuperar sus archivo_key.
def delete_script(id: str, db: Session):
    script = db.query(Script).filter(Script.id_guion == id).first()

    if not script:
        return api_response(False, "Guion no encontrado")

    scene_ids = [s.id_escena for s in db.query(Scene.id_escena).filter(Scene.id_guion == id).all()]

    if scene_ids:
        photo_keys = [
            p.archivo_key
            for p in db.query(GalleryPhoto.archivo_key).filter(GalleryPhoto.id_escena.in_(scene_ids)).all()
        ]
        for key in photo_keys:
            delete_file(BUCKET_IMAGENES, key)

    # Se borra también el PDF en MinIO, si tenía uno cargado.
    delete_file(BUCKET_GUIONES, script.archivo_key)

    db.delete(script)
    db.commit()

    return api_response(True, "Guion y toda su información asociada fueron eliminados")


# ==========================================
# UPLOAD SCRIPT PDF
# ==========================================
# El PDF se sube al bucket "guiones" de MinIO — la base de datos solo
# guarda la ruta del objeto (archivo_key) y los metadatos. Reemplaza el
# archivo anterior si ya había uno (siempre queda solo la última
# versión subida para este registro de guion; el objeto viejo se borra
# de MinIO para no dejar basura huérfana).
async def upload_script_archivo(id: str, file: UploadFile, db: Session):
    script = db.query(Script).filter(Script.id_guion == id).first()

    if not script:
        return api_response(False, "Guion no encontrado", error="SCRIPT_NOT_FOUND")

    if file.content_type not in ALLOWED_CONTENT_TYPES:
        return api_response(False, "Solo se permiten archivos PDF", error="INVALID_FILE_TYPE")

    contenido = await file.read()

    if not contenido:
        return api_response(False, "El archivo está vacío", error="EMPTY_FILE")

    if len(contenido) > MAX_FILE_SIZE_BYTES:
        return api_response(
            False,
            f"El archivo supera el tamaño máximo permitido ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB)",
            error="FILE_TOO_LARGE"
        )

    object_key = f"{script.id_project or 'sin-proyecto'}/{id}_{file.filename}"
    upload_file(BUCKET_GUIONES, object_key, contenido, file.content_type)

    # Ya subido el nuevo, se borra el objeto anterior (si existía y
    # tenía una ruta distinta, ej. cambió el nombre del archivo).
    if script.archivo_key and script.archivo_key != object_key:
        delete_file(BUCKET_GUIONES, script.archivo_key)

    script.archivo_nombre = file.filename
    script.archivo_key = object_key
    script.archivo_tipo = file.content_type
    script.archivo_tamano = len(contenido)

    db.commit()
    db.refresh(script)

    return api_response(True, "Archivo cargado correctamente", {
        "id_guion": script.id_guion,
        "archivo_nombre": script.archivo_nombre,
        "archivo_tamano": script.archivo_tamano
    })


# ==========================================
# GET SCRIPT PDF (visualizar / descargar)
# ==========================================
# El endpoint sigue viviendo detrás de JWT (ver script_routes.py). Una
# vez validado el permiso, el backend trae el binario de MinIO
# (servidor-a-servidor, sin navegador de por medio) y lo devuelve
# directo en la respuesta, igual que antes cuando salía de una columna
# BYTEA — así se evita el problema de CORS de exponer una URL de MinIO
# directo al navegador (ver nota en app/utils/minio_client.py).
def get_script_archivo(id: str, db: Session, current_user: dict):
    script = db.query(Script).filter(Script.id_guion == id).first()

    if not script:
        raise HTTPException(status_code=404, detail="Guion no encontrado")

    if not script.archivo_key:
        raise HTTPException(status_code=404, detail="Este guion todavia no tiene un archivo PDF cargado")

    nombre = script.archivo_nombre or f"guion_{id}.pdf"

    try:
        contenido = download_file(BUCKET_GUIONES, script.archivo_key)
    except Exception:
        raise HTTPException(status_code=404, detail="No se pudo recuperar el archivo desde el almacenamiento")

    # El JWT (current_user) solo trae id_user/mail/id_rol (ver
    # _build_session_response en login_controller.py), no el nombre —
    # por eso hay que ir a buscarlo a la BD para que la marca de agua
    # muestre "Nombre Apellido" en vez del correo.
    usuario_db = db.query(User).filter(User.id_user == current_user.get("id_user")).first()
    if usuario_db and (usuario_db.nombre or usuario_db.apellido):
        texto_marca = f"{usuario_db.nombre or ''} {usuario_db.apellido or ''}".strip()
    else:
        texto_marca = current_user.get("mail", "usuario desconocido")

    try:
        contenido = add_watermark(contenido, texto_marca)
    except Exception:
        # Antes esto era "except Exception: pass": si la marca de agua
        # fallaba por lo que fuera, se servia el PDF original sin marca
        # y sin ningun rastro del error. Se deja el mismo comportamiento
        # (no se rompe la descarga), pero ahora el error queda logueado
        # para poder diagnosticar por que no aparece la marca de agua.
        logger.exception("Fallo al aplicar marca de agua al guion %s", id)

    return Response(
        content=contenido,
        media_type=script.archivo_tipo or "application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nombre}"'}
    )


# ==========================================
# SEGMENTAR GUION POR ESCENAS (automático, heurístico)
# ==========================================
# confirmar=False: analiza el PDF y devuelve la vista previa, sin tocar
# la BD (así el frontend puede mostrar "vamos a crear estas N escenas,
# ¿confirmas?" antes de escribir nada).
# confirmar=True: repite el análisis y esta vez sí crea las escenas.
#
# Los personajes detectados NO se guardan como fichas del catálogo de
# Personajes: esa tabla exige "edad" (obligatoria) y un guion no trae
# esa información, así que crear personajes con edad inventada
# ensuciaría el catálogo. En cambio, quedan anotados como una línea al
# inicio de la descripción de cada escena creada, para que sigan siendo
# útiles al abrir la escena en el módulo de Escenas — quien revise
# puede crear la ficha completa del personaje aparte si hace falta.
def segmentar_script(id: str, confirmar: bool, db: Session):
    script = db.query(Script).filter(Script.id_guion == id).first()

    if not script:
        return api_response(False, "Guion no encontrado", error="SCRIPT_NOT_FOUND")

    if script.estado not in ESTADOS_SEGMENTABLES:
        estados = " o ".join(sorted(ESTADOS_SEGMENTABLES))
        return api_response(
            False,
            f"Para usar la segmentación automática el guion debe estar en estado {estados}. "
            f"Este guion está en estado \"{script.estado}\".",
            error="INVALID_STATE"
        )

    if not script.archivo_key:
        return api_response(False, "Este guion todavía no tiene un archivo PDF cargado", error="NO_FILE")

    try:
        contenido = download_file(BUCKET_GUIONES, script.archivo_key)
    except Exception:
        return api_response(False, "No se pudo recuperar el archivo desde el almacenamiento", error="STORAGE_ERROR")

    try:
        resultado = parse_script(contenido)
    except Exception:
        return api_response(
            False,
            "No se pudo leer el texto de este PDF (¿es un guion escaneado como imagen, sin texto real?)",
            error="PARSE_ERROR"
        )

    escenas_detectadas = resultado["escenas"]

    if not escenas_detectadas:
        return api_response(
            False,
            "No se detectaron escenas automáticamente en este guion. Revisa que los encabezados de escena "
            "sigan el formato estándar (ej. \"INT. LUGAR - DÍA\").",
            error="NO_SCENES_DETECTED"
        )

    if not confirmar:
        return api_response(True, f"Se detectaron {len(escenas_detectadas)} escena(s)", {
            "escenas": escenas_detectadas,
            "personajes_detectados": resultado["personajes_detectados"],
        })

    # ---- confirmar=True: crear de verdad ----
    existentes = {
        s.numero_de_escena
        for s in db.query(Scene.numero_de_escena).filter(Scene.id_guion == id).all()
    }

    # Personajes ya existentes en el catálogo (match por nombre, sin
    # importar mayúsculas/acentos de más o de menos): no se duplican si
    # ya hay un personaje con ese nombre creado a mano o por una
    # segmentación anterior. Acotado al MISMO proyecto del guion — antes
    # buscaba en TODOS los personajes de TODOS los proyectos, lo que
    # además de ser un hueco de aislamiento podía "reutilizar" por error
    # un personaje de otro proyecto que se llamara igual.
    personajes_existentes = {
        c.nombre.strip().upper(): c
        for c in db.query(Character).filter(Character.id_project == script.id_project).all()
    }
    siguiente_codigo = db.query(Character).filter(Character.id_project == script.id_project).count() + 1

    def _personaje_para(nombre: str) -> Character:
        nonlocal siguiente_codigo
        clave = nombre.strip().upper()
        if clave in personajes_existentes:
            return personajes_existentes[clave]

        # Código genérico editable después (mockup no pide un formato
        # fijo) — simplemente correlativo para que no choquen entre sí.
        # id_project es obligatorio en el schema de creación manual
        # (character_schema.py); acá se construye el ORM directo sin
        # pasar por Pydantic, así que hay que setearlo a mano o el
        # personaje quedaría huérfano de proyecto.
        nuevo = Character(
            nombre=nombre.title(),
            edad=0,
            codigo_personaje=f"PERS-{siguiente_codigo:03d}",
            id_project=script.id_project,
        )
        siguiente_codigo += 1
        db.add(nuevo)
        db.flush()  # necesitamos su id_personaje ya para el vínculo con la escena
        personajes_existentes[clave] = nuevo
        return nuevo

    creadas = []
    omitidas = []
    personajes_creados = []
    vinculos = []  # [(Scene, [nombres])] — se resuelven a SceneCharacter después del flush de escenas

    for e in escenas_detectadas:
        if e["numero_de_escena"] in existentes:
            omitidas.append(e["numero_de_escena"])
            continue

        nueva = Scene(
            numero_de_escena=e["numero_de_escena"],
            encabezado=e["encabezado"],
            id_guion=id,
            modo_vista=e["modo_vista"],
            momento_dia=e["momento_dia"],
            pagina=e["pagina"],
            estado="Pendiente",
        )
        db.add(nueva)
        creadas.append(nueva)
        if e["personajes_detectados"]:
            vinculos.append((nueva, e["personajes_detectados"]))

    db.flush()  # asigna id_escena a cada escena nueva antes de crear los vínculos

    for nombre in resultado["personajes_detectados"]:
        antes = nombre.strip().upper() in personajes_existentes
        personaje = _personaje_para(nombre)
        if not antes:
            personajes_creados.append({
                "id_personaje": personaje.id_personaje,
                "nombre": personaje.nombre,
                "codigo_personaje": personaje.codigo_personaje,
            })

    for escena, nombres in vinculos:
        for nombre in nombres:
            personaje = _personaje_para(nombre)
            db.add(SceneCharacter(id_escena=escena.id_escena, id_personaje=personaje.id_personaje))

    db.commit()
    for s in creadas:
        db.refresh(s)

    mensaje = f"{len(creadas)} escena(s) creada(s)"
    if personajes_creados:
        mensaje += f", {len(personajes_creados)} personaje(s) nuevo(s)"
    if omitidas:
        mensaje += f", {len(omitidas)} escena(s) ya existían"

    return api_response(True, mensaje, {
        "escenas_creadas": [
            {
                "id_escena": s.id_escena,
                "numero_de_escena": s.numero_de_escena,
                "encabezado": s.encabezado,
            }
            for s in creadas
        ],
        "omitidas": omitidas,
        "personajes_detectados": resultado["personajes_detectados"],
        "personajes_creados": personajes_creados,
    })
