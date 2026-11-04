import re
from datetime import date

from fastapi import HTTPException, UploadFile
from fastapi.responses import Response
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models.department_model import Department
from app.models.inventory_model import InventoryItem, InventoryPhoto
from app.schemas.inventory_schema import GENEROS_INVENTARIO
from app.utils.minio_client import BUCKET_IMAGENES, upload_file, delete_file, download_file
from app.utils.response import api_response

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB
MAX_FOTOS = 3  # por elemento, individuales (sin collage)
MAX_PAGE_SIZE = 200
PREFIJO_CODIGO = "INV-"


def _fotos_de(db: Session, id_item) -> list[InventoryPhoto]:
    return (
        db.query(InventoryPhoto)
        .filter(InventoryPhoto.id_item == id_item)
        .order_by(InventoryPhoto.orden, InventoryPhoto.fecha_subida)
        .all()
    )


def _serialize(i: InventoryItem, departamento: str | None = None, fotos: list[InventoryPhoto] | None = None):
    fotos = fotos or []
    return {
        "id_item": i.id_item,
        "id_project": i.id_project,
        "codigo": i.codigo,
        "tipo": i.tipo,
        "color_predominante": i.color_predominante,
        "genero": i.genero,
        "descripcion": i.descripcion,
        "cantidad": i.cantidad,
        "origen": i.origen,
        "destino": i.destino,
        "composicion": i.composicion,
        "fecha_ingreso": i.fecha_ingreso.isoformat() if i.fecha_ingreso else None,
        "id_departamento": i.id_departamento,
        "departamento_nombre": departamento,
        # Fotos individuales (máx. 3), en orden: la primera es la portada.
        "fotos": [
            {"id_foto": f.id_foto, "orden": f.orden, "archivo_nombre": f.archivo_nombre}
            for f in fotos
        ],
        "tiene_foto": len(fotos) > 0,
        "fecha_creacion": i.fecha_creacion.isoformat() if i.fecha_creacion else None,
        "fecha_actualizacion": i.fecha_actualizacion.isoformat() if i.fecha_actualizacion else None,
    }


def _serialize_full(db: Session, i: InventoryItem):
    return _serialize(i, _nombre_depto(db, i.id_departamento), _fotos_de(db, i.id_item))


def _nombre_depto(db: Session, id_departamento) -> str | None:
    if not id_departamento:
        return None
    d = db.query(Department).filter(Department.id_departamento == id_departamento).first()
    return d.nombre if d else None


def _like_escape(texto: str) -> str:
    return texto.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _migrar_legado(db: Session, id_project):
    """Elementos creados antes de las fotos múltiples tenían su única foto
    en inventario.archivo_*: se copia a inventario_fotos (sin mover el
    archivo en MinIO) la primera vez que se lista el proyecto."""
    pendientes = (
        db.query(InventoryItem)
        .filter(
            InventoryItem.id_project == id_project,
            InventoryItem.archivo_key.isnot(None),
            ~db.query(InventoryPhoto.id_foto).filter(InventoryPhoto.id_item == InventoryItem.id_item).exists(),
        )
        .all()
    )
    if not pendientes:
        return
    for it in pendientes:
        db.add(InventoryPhoto(
            id_item=it.id_item,
            orden=1,
            archivo_nombre=it.archivo_nombre or "foto.jpg",
            archivo_key=it.archivo_key,
            archivo_tipo=it.archivo_tipo or "image/jpeg",
            archivo_tamano=it.archivo_tamano or 0,
        ))
        # Ya migrada: se limpia para no volver a copiarla si luego se
        # borran todas sus fotos.
        it.archivo_key = None
    db.commit()


def _siguiente_codigo(db: Session, id_project) -> str:
    """INV-0001, INV-0002... según el mayor código INV-#### del proyecto."""
    codigos = (
        db.query(InventoryItem.codigo)
        .filter(InventoryItem.id_project == id_project, InventoryItem.codigo.like(f"{PREFIJO_CODIGO}%"))
        .all()
    )
    mayor = 0
    for (c,) in codigos:
        m = re.fullmatch(rf"{PREFIJO_CODIGO}(\d+)", c or "")
        if m:
            mayor = max(mayor, int(m.group(1)))
    return f"{PREFIJO_CODIGO}{mayor + 1:04d}"


def _codigo_existe(db: Session, id_project, codigo: str, excluir_id=None) -> bool:
    q = db.query(InventoryItem).filter(
        InventoryItem.id_project == id_project,
        func.lower(InventoryItem.codigo) == codigo.lower(),
    )
    if excluir_id is not None:
        q = q.filter(InventoryItem.id_item != excluir_id)
    return db.query(q.exists()).scalar()


def _validar_foto(file: UploadFile, contenido: bytes):
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        return api_response(False, "Solo se permiten imágenes JPEG, PNG o WEBP", error="INVALID_FILE_TYPE")
    if not contenido:
        return api_response(False, "El archivo está vacío", error="EMPTY_FILE")
    if len(contenido) > MAX_FILE_SIZE_BYTES:
        return api_response(
            False,
            f"El archivo supera el tamaño máximo permitido ({MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB)",
            error="FILE_TOO_LARGE",
        )
    return None


def _agregar_foto(db: Session, item: InventoryItem, file: UploadFile, contenido: bytes) -> InventoryPhoto:
    """Sube la imagen a MinIO y crea su fila (el llamador valida el tope)."""
    import uuid

    id_foto = uuid.uuid4()
    nombre = file.filename or "foto.jpg"
    key = f"inventario/{item.id_project}/{item.id_item}/{id_foto}_{nombre}"
    upload_file(BUCKET_IMAGENES, key, contenido, file.content_type)

    ultimo = db.query(func.coalesce(func.max(InventoryPhoto.orden), 0)).filter(InventoryPhoto.id_item == item.id_item).scalar()
    foto = InventoryPhoto(
        id_foto=id_foto,
        id_item=item.id_item,
        orden=int(ultimo or 0) + 1,
        archivo_nombre=nombre,
        archivo_key=key,
        archivo_tipo=file.content_type,
        archivo_tamano=len(contenido),
    )
    db.add(foto)
    return foto


# ==========================================
# LISTAR / BUSCAR (paginado, solo metadatos)
# ==========================================
def list_items(
    id_project: str,
    db: Session,
    q: str | None = None,
    tipo: str | None = None,
    color: str | None = None,
    genero: str | None = None,
    id_departamento: str | None = None,
    page: int = 1,
    page_size: int = 60,
):
    _migrar_legado(db, id_project)

    page = max(1, page)
    page_size = max(1, min(page_size, MAX_PAGE_SIZE))

    query = (
        db.query(InventoryItem, Department.nombre)
        .outerjoin(Department, InventoryItem.id_departamento == Department.id_departamento)
        .filter(InventoryItem.id_project == id_project)
    )

    if q and q.strip():
        patron = f"%{_like_escape(q.strip())}%"
        query = query.filter(or_(
            InventoryItem.codigo.ilike(patron, escape="\\"),
            InventoryItem.descripcion.ilike(patron, escape="\\"),
            InventoryItem.origen.ilike(patron, escape="\\"),
            InventoryItem.destino.ilike(patron, escape="\\"),
            InventoryItem.composicion.ilike(patron, escape="\\"),
            InventoryItem.tipo.ilike(patron, escape="\\"),
            InventoryItem.color_predominante.ilike(patron, escape="\\"),
        ))
    if tipo:
        query = query.filter(InventoryItem.tipo == tipo)
    if color:
        query = query.filter(InventoryItem.color_predominante == color)
    if genero:
        query = query.filter(InventoryItem.genero == genero)
    if id_departamento:
        query = query.filter(InventoryItem.id_departamento == id_departamento)

    total = query.order_by(None).count()
    # Cantidad total de unidades de lo filtrado (suma de "cantidad").
    unidades = (
        query.with_entities(func.coalesce(func.sum(InventoryItem.cantidad), 0)).order_by(None).scalar()
    )

    rows = (
        query.order_by(InventoryItem.fecha_creacion.desc(), InventoryItem.id_item)
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    # Fotos de TODA la página en una sola consulta (evita N+1).
    ids = [i.id_item for i, _ in rows]
    por_item: dict = {}
    if ids:
        for f in (
            db.query(InventoryPhoto)
            .filter(InventoryPhoto.id_item.in_(ids))
            .order_by(InventoryPhoto.orden, InventoryPhoto.fecha_subida)
            .all()
        ):
            por_item.setdefault(f.id_item, []).append(f)

    return api_response(True, "Inventario del proyecto", {
        "items": [_serialize(i, dep, por_item.get(i.id_item, [])) for i, dep in rows],
        "total": total,
        "unidades": int(unidades or 0),
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    })


# ==========================================
# CREAR (multipart: datos + primera foto opcional)
# ==========================================
async def create_item(
    id_project: str,
    data: dict,
    file: UploadFile | None,
    db: Session,
    current_user: dict,
):
    tipo = (data.get("tipo") or "").strip()
    if not tipo:
        return api_response(False, "El tipo de elemento es obligatorio", error="TIPO_REQUIRED")

    genero = (data.get("genero") or "").strip() or None
    if genero and genero not in GENEROS_INVENTARIO:
        return api_response(False, f"Género inválido. Use: {', '.join(GENEROS_INVENTARIO)}", error="INVALID_GENDER")

    cantidad = data.get("cantidad")
    cantidad = 1 if cantidad is None else cantidad
    if cantidad < 0:
        return api_response(False, "La cantidad no puede ser negativa", error="INVALID_QUANTITY")

    contenido = None
    if file is not None and file.filename:
        contenido = await file.read()
        error = _validar_foto(file, contenido)
        if error:
            return error

    codigo = (data.get("codigo") or "").strip()
    if codigo:
        if _codigo_existe(db, id_project, codigo):
            return api_response(False, f'Ya existe un elemento con el código "{codigo}" en este proyecto', error="CODE_EXISTS")
    else:
        codigo = _siguiente_codigo(db, id_project)

    id_departamento = data.get("id_departamento") or None
    if id_departamento and not _nombre_depto(db, id_departamento):
        return api_response(False, "Departamento no encontrado", error="DEPARTMENT_NOT_FOUND")

    # Fecha de ingreso: la que envíe la persona o, si no, el día actual.
    fecha_ingreso = date.today()
    raw_fecha = (data.get("fecha_ingreso") or "").strip() if isinstance(data.get("fecha_ingreso"), str) else data.get("fecha_ingreso")
    if raw_fecha:
        try:
            fecha_ingreso = raw_fecha if isinstance(raw_fecha, date) else date.fromisoformat(raw_fecha)
        except ValueError:
            return api_response(False, "Fecha de ingreso inválida (use AAAA-MM-DD)", error="INVALID_DATE")

    item = InventoryItem(
        fecha_ingreso=fecha_ingreso,
        id_project=id_project,
        codigo=codigo,
        tipo=tipo,
        color_predominante=(data.get("color_predominante") or "").strip() or None,
        genero=genero,
        descripcion=(data.get("descripcion") or "").strip() or None,
        cantidad=cantidad,
        origen=(data.get("origen") or "").strip() or None,
        destino=(data.get("destino") or "").strip() or None,
        composicion=(data.get("composicion") or "").strip() or None,
        id_departamento=id_departamento,
        creado_por=current_user.get("id_user"),
    )
    db.add(item)
    db.flush()  # asigna id_item (uuid) antes de armar la ruta en MinIO

    if contenido:
        _agregar_foto(db, item, file, contenido)

    db.commit()
    db.refresh(item)
    return api_response(True, "Elemento creado en el inventario", _serialize_full(db, item))


# ==========================================
# OBTENER UNO
# ==========================================
def get_item(id_item: str, db: Session):
    item = db.query(InventoryItem).filter(InventoryItem.id_item == id_item).first()
    if not item:
        return api_response(False, "Elemento no encontrado", error="ITEM_NOT_FOUND")
    _migrar_legado(db, item.id_project)
    return api_response(True, "Elemento del inventario", _serialize_full(db, item))


# ==========================================
# EDITAR (parcial)
# ==========================================
def update_item(id_item: str, data: dict, db: Session):
    item = db.query(InventoryItem).filter(InventoryItem.id_item == id_item).first()
    if not item:
        return api_response(False, "Elemento no encontrado", error="ITEM_NOT_FOUND")

    if "tipo" in data and not data["tipo"]:
        return api_response(False, "El tipo de elemento es obligatorio", error="TIPO_REQUIRED")

    if "codigo" in data:
        nuevo = data["codigo"]
        if not nuevo:
            return api_response(False, "El código no puede quedar vacío", error="CODE_REQUIRED")
        if _codigo_existe(db, item.id_project, nuevo, excluir_id=item.id_item):
            return api_response(False, f'Ya existe un elemento con el código "{nuevo}" en este proyecto', error="CODE_EXISTS")

    if data.get("id_departamento") and not _nombre_depto(db, data["id_departamento"]):
        return api_response(False, "Departamento no encontrado", error="DEPARTMENT_NOT_FOUND")

    if "cantidad" in data and data["cantidad"] is None:
        data.pop("cantidad")
    if "fecha_ingreso" in data and data["fecha_ingreso"] is None:
        data.pop("fecha_ingreso")  # columna obligatoria: no se permite vaciarla

    for campo, valor in data.items():
        setattr(item, campo, valor)

    db.commit()
    db.refresh(item)
    return api_response(True, "Elemento actualizado", _serialize_full(db, item))


# ==========================================
# AGREGAR FOTO (máx. 3 por elemento, individuales)
# ==========================================
async def add_photo(id_item: str, file: UploadFile, db: Session):
    item = db.query(InventoryItem).filter(InventoryItem.id_item == id_item).first()
    if not item:
        return api_response(False, "Elemento no encontrado", error="ITEM_NOT_FOUND")

    _migrar_legado(db, item.id_project)

    cantidad = db.query(func.count(InventoryPhoto.id_foto)).filter(InventoryPhoto.id_item == item.id_item).scalar()
    if cantidad >= MAX_FOTOS:
        return api_response(False, f"Máximo {MAX_FOTOS} fotos por elemento", error="MAX_PHOTOS")

    contenido = await file.read()
    error = _validar_foto(file, contenido)
    if error:
        return error

    _agregar_foto(db, item, file, contenido)
    db.commit()
    db.refresh(item)
    return api_response(True, "Foto agregada", _serialize_full(db, item))


# ==========================================
# VER FOTO (binario; el backend la trae de MinIO, ver minio_client.py)
# ==========================================
def get_photo_archivo(id_foto: str, db: Session):
    foto = db.query(InventoryPhoto).filter(InventoryPhoto.id_foto == id_foto).first()
    if not foto:
        raise HTTPException(status_code=404, detail="Foto no encontrada")

    try:
        contenido = download_file(BUCKET_IMAGENES, foto.archivo_key)
    except Exception:
        raise HTTPException(status_code=404, detail="No se pudo recuperar el archivo desde el almacenamiento")

    return Response(
        content=contenido,
        media_type=foto.archivo_tipo or "image/jpeg",
        headers={"Content-Disposition": f'inline; filename="{foto.archivo_nombre or "foto.jpg"}"'},
    )


# ==========================================
# ELIMINAR UNA FOTO
# ==========================================
def delete_photo(id_foto: str, db: Session):
    foto = db.query(InventoryPhoto).filter(InventoryPhoto.id_foto == id_foto).first()
    if not foto:
        return api_response(False, "Foto no encontrada", error="PHOTO_NOT_FOUND")

    item = db.query(InventoryItem).filter(InventoryItem.id_item == foto.id_item).first()
    delete_file(BUCKET_IMAGENES, foto.archivo_key)
    db.delete(foto)
    db.flush()

    # Reordena 1..n para que la portada siempre sea la primera.
    for n, f in enumerate(_fotos_de(db, foto.id_item), start=1):
        f.orden = n

    db.commit()
    return api_response(True, "Foto eliminada", _serialize_full(db, item) if item else None)


# ==========================================
# ELIMINAR EL ELEMENTO (borra la fila y TODAS sus fotos en MinIO)
# ==========================================
def delete_item(id_item: str, db: Session):
    item = db.query(InventoryItem).filter(InventoryItem.id_item == id_item).first()
    if not item:
        return api_response(False, "Elemento no encontrado", error="ITEM_NOT_FOUND")

    for f in _fotos_de(db, item.id_item):
        delete_file(BUCKET_IMAGENES, f.archivo_key)
    if item.archivo_key:  # foto legada aún sin migrar
        delete_file(BUCKET_IMAGENES, item.archivo_key)

    db.delete(item)  # las filas de inventario_fotos caen por ON DELETE CASCADE
    db.commit()
    return api_response(True, "Elemento eliminado del inventario")
