from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.database import get_db
from app.controllers.breakdown_controller import (
    get_items_by_scene,
    get_item,
    create_item,
    update_item_full,
    update_item,
    delete_item,
    get_detalle_by_item,
    create_detalle,
    update_detalle_full,
    update_detalle,
    delete_detalle,
    get_pendientes_mi_departamento
)
from app.schemas.breakdown_schema import (
    DesgloseItemSchema,
    DesgloseItemUpdateSchema,
    DesgloseDetalleSchema,
    DesgloseDetalleUpdateSchema
)
from app.models.scene_model import Scene
from app.models.breakdown_model import DesgloseItem, DesgloseItemDetalle
from app.utils.response import api_response

# 🔐 autenticación / permisos — resueltos por proyecto, ver
# app/utils/project_scope.py. Ninguno de estos modelos tiene columna
# id_project propia: se resuelve subiendo por id_escena -> id_guion ->
# guiones.id_project (o, para el detalle, un nivel más arriba todavía:
# detalle -> item -> escena -> guion -> proyecto).
from app.middleware.auth import get_current_user
from app.utils.project_scope import (
    require_project_member,
    require_record_project_permission,
    check_project_permission,
    resolve_project_of_scene,
    resolve_project_via_scene_fk,
    resolve_project_via_desglose_item,
)

router = APIRouter()


# ==========================================
# NIVEL GENERAL (desglose_items)
# ==========================================
# Lectura abierta a cualquier miembro del proyecto de la escena.
# Escritura solo Administrador/Director (permiso
# "manage_general_breakdown"), resuelto dentro de ESE proyecto.
@router.get("/breakdown/items/scene/{id_escena}")
def items_by_scene(
    id_escena: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=Scene, pk_column="id_escena", pk_path_param="id_escena",
        resolve_project=resolve_project_of_scene, not_found_message="Escena no encontrada",
    )),
):
    return get_items_by_scene(id_escena, db)

@router.get("/breakdown/items/{id}")
def item(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        None, model=DesgloseItem, pk_column="id_desglose_item",
        resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return get_item(id, db)

@router.post("/breakdown/items")
def store_item(item: DesgloseItemSchema, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    scene = db.query(Scene).filter(Scene.id_escena == item.id_escena).first()
    if not scene:
        return api_response(False, "Escena no encontrada")
    id_project = resolve_project_of_scene(scene, db)
    check_project_permission(db, current_user, id_project, "manage_general_breakdown")
    return create_item(item, db, current_user)

@router.put("/breakdown/items/{id}")
def edit_item(
    id: str,
    item: DesgloseItemSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "manage_general_breakdown", model=DesgloseItem, pk_column="id_desglose_item",
        resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return update_item_full(id, item, db)

@router.patch("/breakdown/items/{id}")
def patch_item(
    id: str,
    item: DesgloseItemUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "manage_general_breakdown", model=DesgloseItem, pk_column="id_desglose_item",
        resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return update_item(id, item, db)

@router.delete("/breakdown/items/{id}")
def destroy_item(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "manage_general_breakdown", model=DesgloseItem, pk_column="id_desglose_item",
        resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return delete_item(id, db)


# ==========================================
# NIVEL ESPECIFICO (desglose_item_detalle)
# ==========================================
# La dependencia exige pertenecer al proyecto Y (para editar) el
# permiso de rol "view/edit_department_breakdown" en ESE proyecto
# (Administrador/Director quedan fuera porque en la matriz esos
# permisos son False para ellos). El match por id_departamento se
# valida ADEMÁS dentro del controller, como ya hacía antes.
@router.get("/breakdown/items/{id_desglose_item}/detalle")
def detalle_by_item(
    id_desglose_item: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "view_department_breakdown", model=DesgloseItem, pk_column="id_desglose_item",
        pk_path_param="id_desglose_item", resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return get_detalle_by_item(id_desglose_item, db, current_user)

@router.post("/breakdown/items/{id_desglose_item}/detalle")
def store_detalle(
    id_desglose_item: str,
    detalle: DesgloseDetalleSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "edit_department_breakdown", model=DesgloseItem, pk_column="id_desglose_item",
        pk_path_param="id_desglose_item", resolve_project=resolve_project_via_scene_fk("id_escena"),
        not_found_message="Item de desglose no encontrado",
    )),
):
    return create_detalle(id_desglose_item, detalle, db, current_user)

@router.put("/breakdown/detalle/{id}")
def edit_detalle(
    id: str,
    detalle: DesgloseDetalleSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "edit_department_breakdown", model=DesgloseItemDetalle, pk_column="id_detalle",
        resolve_project=resolve_project_via_desglose_item,
        not_found_message="Segmentación no encontrada",
    )),
):
    return update_detalle_full(id, detalle, db, current_user)

@router.patch("/breakdown/detalle/{id}")
def patch_detalle(
    id: str,
    detalle: DesgloseDetalleUpdateSchema,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "edit_department_breakdown", model=DesgloseItemDetalle, pk_column="id_detalle",
        resolve_project=resolve_project_via_desglose_item,
        not_found_message="Segmentación no encontrada",
    )),
):
    return update_detalle(id, detalle, db, current_user)

@router.delete("/breakdown/detalle/{id}")
def destroy_detalle(
    id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_record_project_permission(
        "edit_department_breakdown", model=DesgloseItemDetalle, pk_column="id_detalle",
        resolve_project=resolve_project_via_desglose_item,
        not_found_message="Segmentación no encontrada",
    )),
):
    return delete_detalle(id, db, current_user)


# ==========================================
# PENDIENTES DEL PROPIO DEPARTAMENTO
# ==========================================
# Antes /breakdown/pendientes no recibía proyecto: como Department es
# un catálogo global (no tiene id_project), esto cruzaba pendientes de
# TODOS los proyectos donde el departamento del usuario tuviera items.
@router.get("/breakdown/pendientes/project/{id_project}")
def pendientes_mi_departamento(id_project: str, db: Session = Depends(get_db), current_user: dict = Depends(require_project_member())):
    return get_pendientes_mi_departamento(id_project, db, current_user)
