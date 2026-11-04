from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session

from app.config.database import get_db
from app.controllers.inventory_controller import (
    list_items,
    create_item,
    get_item,
    update_item,
    add_photo,
    get_photo_archivo,
    delete_photo,
    delete_item,
)
from app.models.inventory_model import InventoryItem, InventoryPhoto
from app.schemas.inventory_schema import InventoryUpdateSchema
from app.utils.module_access import check_module_min_level
from app.utils.project_scope import require_project_member, require_record_project_permission

router = APIRouter()

# ==========================================
# INVENTARIO — todo se decide por el NIVEL de módulo "inventario"
# (ver app/utils/module_access.py), no por permisos booleanos del rol:
#   ver         -> listar / ver fotos
#   editar      -> crear, editar datos, subir/cambiar foto
#   administrar -> eliminar
# Todos los roles parten con "administrar"; desde "Personalizar
# accesos" se le puede bajar el nivel a una persona puntual.
# ==========================================


def _record_member():
    """Dependencia para rutas con {id_item}: resuelve el proyecto del
    elemento y exige pertenecer a él (devuelve id_rol e id_project)."""
    return require_record_project_permission(
        None, model=InventoryItem, pk_column="id_item", pk_path_param="id_item",
        not_found_message="Elemento no encontrado",
    )


@router.get("/inventario/project/{id_project}")
def inventory_list(
    id_project: str,
    q: str | None = None,
    tipo: str | None = None,
    color: str | None = None,
    genero: str | None = None,
    id_departamento: str | None = None,
    page: int = 1,
    page_size: int = 60,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_member()),
):
    check_module_min_level(db, current_user, id_project, "inventario", current_user.get("id_rol"), "ver")
    return list_items(id_project, db, q, tipo, color, genero, id_departamento, page, page_size)


@router.post("/inventario/project/{id_project}")
async def inventory_create(
    id_project: str,
    tipo: str = Form(...),
    codigo: str | None = Form(None),
    color_predominante: str | None = Form(None),
    genero: str | None = Form(None),
    descripcion: str | None = Form(None),
    cantidad: int = Form(1),
    origen: str | None = Form(None),
    destino: str | None = Form(None),
    composicion: str | None = Form(None),
    id_departamento: str | None = Form(None),
    fecha_ingreso: str | None = Form(None),
    file: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_project_member()),
):
    check_module_min_level(db, current_user, id_project, "inventario", current_user.get("id_rol"), "editar")
    data = {
        "tipo": tipo, "codigo": codigo, "color_predominante": color_predominante,
        "genero": genero, "descripcion": descripcion, "cantidad": cantidad,
        "origen": origen, "destino": destino, "composicion": composicion,
        "id_departamento": id_departamento, "fecha_ingreso": fecha_ingreso,
    }
    return await create_item(id_project, data, file, db, current_user)


@router.get("/inventario/{id_item}")
def inventory_get(
    id_item: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(_record_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "ver")
    return get_item(id_item, db)


@router.patch("/inventario/{id_item}")
def inventory_update(
    id_item: str,
    data: InventoryUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(_record_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "editar")
    return update_item(id_item, data.model_dump(exclude_unset=True), db)


# Fotos: hasta 3 por elemento, individuales (sin collage).
@router.post("/inventario/{id_item}/fotos")
async def inventory_photo_add(
    id_item: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(_record_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "editar")
    return await add_photo(id_item, file, db)


def _resolve_project_of_photo(foto, db: Session):
    item = db.query(InventoryItem).filter(InventoryItem.id_item == foto.id_item).first()
    return item.id_project if item else None


def _photo_member():
    return require_record_project_permission(
        None, model=InventoryPhoto, pk_column="id_foto", pk_path_param="id_foto",
        resolve_project=_resolve_project_of_photo, not_found_message="Foto no encontrada",
    )


@router.get("/inventario/fotos/{id_foto}/archivo")
def inventory_photo(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(_photo_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "ver")
    return get_photo_archivo(id_foto, db)


@router.delete("/inventario/fotos/{id_foto}")
def inventory_photo_delete(
    id_foto: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(_photo_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "editar")
    return delete_photo(id_foto, db)


@router.delete("/inventario/{id_item}")
def inventory_delete(
    id_item: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(_record_member()),
):
    check_module_min_level(db, current_user, current_user["id_project"], "inventario", current_user.get("id_rol"), "administrar")
    return delete_item(id_item, db)
