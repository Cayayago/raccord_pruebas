from sqlalchemy.orm import Session

from app.models.breakdown_model import DesgloseItem, DesgloseItemDetalle
from app.models.user_model import User
from app.models.scene_model import Scene
from app.models.script_model import Script

from app.schemas.breakdown_schema import DesgloseItemSchema, DesgloseDetalleSchema
from app.utils.permissions import ADMINISTRADOR, DIRECTOR

from app.utils.response import api_response


# ==========================================
# HELPER: DEPARTAMENTO DEL USUARIO ACTUAL
# ==========================================
# El JWT solo trae id_user / mail / id_rol (ver login_controller), no
# id_departamento. Se consulta siempre fresco contra la BD para saber
# a qué área pertenece quien hace la petición.
def _get_user_departamento(current_user: dict, db: Session):
    user = db.query(User).filter(User.id_user == current_user.get("id_user")).first()
    return user.id_departamento if user else None


def _mismo_departamento(current_user: dict, id_departamento_item, db: Session) -> bool:
    return _get_user_departamento(current_user, db) == id_departamento_item


# ==========================================
# SERIALIZADORES
# ==========================================
def _serialize_item(i: DesgloseItem):
    return {
        "id_desglose_item": i.id_desglose_item,
        "id_escena": i.id_escena,
        "id_departamento": i.id_departamento,
        "categoria": i.categoria,
        "nombre_item": i.nombre_item,
        "cantidad": i.cantidad,
        "notas": i.notas,
        "id_user_creador": i.id_user_creador,
        "created_at": str(i.created_at) if i.created_at else None,
        "updated_at": str(i.updated_at) if i.updated_at else None,
    }


def _serialize_detalle(d: DesgloseItemDetalle):
    return {
        "id_detalle": d.id_detalle,
        "id_desglose_item": d.id_desglose_item,
        "etiqueta": d.etiqueta,
        "cantidad": d.cantidad,
        "estado": d.estado,
        "prioridad": d.prioridad,
        "notas": d.notas,
        "id_user_editor": d.id_user_editor,
        "updated_at": str(d.updated_at) if d.updated_at else None,
    }


# ==========================================
# NIVEL GENERAL — DESGLOSE_ITEMS
# ==========================================
# Lectura abierta a cualquier usuario autenticado (igual que
# departamentos/guiones/escenas). Escritura reservada a
# Administrador/Director vía permiso "manage_general_breakdown"
# (aplicado en las routes).
def get_items_by_scene(id_escena: str, db: Session):
    items = db.query(DesgloseItem).filter(
        DesgloseItem.id_escena == id_escena
    ).order_by(DesgloseItem.categoria, DesgloseItem.id_desglose_item).all()

    return api_response(True, "Desglose general de la escena", [_serialize_item(i) for i in items])


def get_item(id: str, db: Session):
    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id).first()

    if not item:
        return api_response(False, "Item de desglose no encontrado")

    return api_response(True, "Item encontrado", _serialize_item(item))


def create_item(item: DesgloseItemSchema, db: Session, current_user: dict):
    new_item = DesgloseItem(
        id_escena=item.id_escena,
        id_departamento=item.id_departamento,
        categoria=item.categoria,
        nombre_item=item.nombre_item,
        cantidad=item.cantidad,
        notas=item.notas,
        id_user_creador=current_user.get("id_user")
    )

    db.add(new_item)
    db.commit()
    db.refresh(new_item)

    return api_response(True, "Item de desglose creado", _serialize_item(new_item))


def _resolve_project_of_escena(id_escena, db: Session):
    if not id_escena:
        return None
    scene = db.query(Scene).filter(Scene.id_escena == id_escena).first()
    if not scene or not scene.id_guion:
        return None
    return db.query(Script.id_project).filter(Script.id_guion == scene.id_guion).scalar()


def update_item_full(id: str, item: DesgloseItemSchema, db: Session):
    item_db = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id).first()

    if not item_db:
        return api_response(False, "Item de desglose no encontrado")

    # No se puede mover el item a una escena de OTRO proyecto (mismo
    # guard que en scene_controller.py con id_guion).
    if item.id_escena and str(item.id_escena) != str(item_db.id_escena):
        if _resolve_project_of_escena(item.id_escena, db) != _resolve_project_of_escena(item_db.id_escena, db):
            return api_response(False, "No se puede mover el item a una escena de otro proyecto", error="CROSS_PROJECT_MOVE")

    item_db.id_escena = item.id_escena
    item_db.id_departamento = item.id_departamento
    item_db.categoria = item.categoria
    item_db.nombre_item = item.nombre_item
    item_db.cantidad = item.cantidad
    item_db.notas = item.notas

    db.commit()
    db.refresh(item_db)

    return api_response(True, "Item de desglose actualizado", _serialize_item(item_db))


def update_item(id: str, item, db: Session):
    item_db = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id).first()

    if not item_db:
        return api_response(False, "Item de desglose no encontrado")

    update_data = item.model_dump(exclude_unset=True)

    if update_data.get("id_escena") and str(update_data["id_escena"]) != str(item_db.id_escena):
        if _resolve_project_of_escena(update_data["id_escena"], db) != _resolve_project_of_escena(item_db.id_escena, db):
            return api_response(False, "No se puede mover el item a una escena de otro proyecto", error="CROSS_PROJECT_MOVE")

    for key, value in update_data.items():
        setattr(item_db, key, value)

    db.commit()
    db.refresh(item_db)

    return api_response(True, "Item de desglose actualizado", _serialize_item(item_db))


# id_desglose_item.detalle tiene ON DELETE CASCADE hacia desglose_items:
# borrar el item general borra también la segmentación que haya hecho
# el departamento. Se avisa cuántas filas de detalle se pierden.
def delete_item(id: str, db: Session):
    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id).first()

    if not item:
        return api_response(False, "Item de desglose no encontrado")

    detalle_count = db.query(DesgloseItemDetalle).filter(
        DesgloseItemDetalle.id_desglose_item == id
    ).count()

    db.delete(item)
    db.commit()

    mensaje = "Item de desglose eliminado"
    if detalle_count > 0:
        mensaje += f" (se eliminó también la segmentación del departamento: {detalle_count} fila(s))"

    return api_response(True, mensaje)


# ==========================================
# NIVEL ESPECIFICO — DESGLOSE_ITEM_DETALLE
# ==========================================
# Administrador/Director NUNCA llegan aquí: la ruta ya los bloquea con
# require_permission("view_department_breakdown"/"edit_department_breakdown"),
# que en la matriz vale False para esos dos roles. Lo que se valida acá
# es que el usuario (Jefe/Onset/Usuario) pertenezca al MISMO
# departamento dueño del item — si no, no ve ni edita, aunque tenga el
# permiso de rol.
def get_detalle_by_item(id_desglose_item: str, db: Session, current_user: dict):
    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id_desglose_item).first()

    if not item:
        return api_response(False, "Item de desglose no encontrado")

    if not _mismo_departamento(current_user, item.id_departamento, db):
        return api_response(False, "No tienes acceso al desglose específico de este departamento", error="FORBIDDEN_DEPARTMENT")

    detalle = db.query(DesgloseItemDetalle).filter(
        DesgloseItemDetalle.id_desglose_item == id_desglose_item
    ).order_by(DesgloseItemDetalle.id_detalle).all()

    return api_response(True, "Segmentación del departamento", [_serialize_detalle(d) for d in detalle])


def create_detalle(id_desglose_item: str, detalle: DesgloseDetalleSchema, db: Session, current_user: dict):
    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == id_desglose_item).first()

    if not item:
        return api_response(False, "Item de desglose no encontrado")

    if not _mismo_departamento(current_user, item.id_departamento, db):
        return api_response(False, "No puedes editar el desglose específico de otro departamento", error="FORBIDDEN_DEPARTMENT")

    new_detalle = DesgloseItemDetalle(
        id_desglose_item=id_desglose_item,
        etiqueta=detalle.etiqueta,
        cantidad=detalle.cantidad,
        estado=detalle.estado,
        prioridad=detalle.prioridad,
        notas=detalle.notas,
        id_user_editor=current_user.get("id_user")
    )

    db.add(new_detalle)
    db.commit()
    db.refresh(new_detalle)

    return api_response(True, "Segmentación creada", _serialize_detalle(new_detalle))


def _get_detalle_con_item(id_detalle: str, db: Session):
    detalle = db.query(DesgloseItemDetalle).filter(DesgloseItemDetalle.id_detalle == id_detalle).first()

    if not detalle:
        return None, None

    item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == detalle.id_desglose_item).first()

    return detalle, item


def update_detalle_full(id_detalle: str, detalle: DesgloseDetalleSchema, db: Session, current_user: dict):
    detalle_db, item = _get_detalle_con_item(id_detalle, db)

    if not detalle_db:
        return api_response(False, "Segmentación no encontrada")

    if not _mismo_departamento(current_user, item.id_departamento if item else None, db):
        return api_response(False, "No puedes editar el desglose específico de otro departamento", error="FORBIDDEN_DEPARTMENT")

    detalle_db.etiqueta = detalle.etiqueta
    detalle_db.cantidad = detalle.cantidad
    detalle_db.estado = detalle.estado
    detalle_db.prioridad = detalle.prioridad
    detalle_db.notas = detalle.notas
    detalle_db.id_user_editor = current_user.get("id_user")

    db.commit()
    db.refresh(detalle_db)

    return api_response(True, "Segmentación actualizada", _serialize_detalle(detalle_db))


def update_detalle(id_detalle: str, detalle, db: Session, current_user: dict):
    detalle_db, item = _get_detalle_con_item(id_detalle, db)

    if not detalle_db:
        return api_response(False, "Segmentación no encontrada")

    if not _mismo_departamento(current_user, item.id_departamento if item else None, db):
        return api_response(False, "No puedes editar el desglose específico de otro departamento", error="FORBIDDEN_DEPARTMENT")

    update_data = detalle.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(detalle_db, key, value)

    detalle_db.id_user_editor = current_user.get("id_user")

    db.commit()
    db.refresh(detalle_db)

    return api_response(True, "Segmentación actualizada", _serialize_detalle(detalle_db))


def delete_detalle(id_detalle: str, db: Session, current_user: dict):
    detalle_db, item = _get_detalle_con_item(id_detalle, db)

    if not detalle_db:
        return api_response(False, "Segmentación no encontrada")

    if not _mismo_departamento(current_user, item.id_departamento if item else None, db):
        return api_response(False, "No puedes eliminar el desglose específico de otro departamento", error="FORBIDDEN_DEPARTMENT")

    db.delete(detalle_db)
    db.commit()

    return api_response(True, "Segmentación eliminada")


# ==========================================
# PENDIENTES DEL PROPIO DEPARTAMENTO
# ==========================================
# Lista de tareas (filas de detalle) que el área todavía debe resolver,
# ordenadas por prioridad (alta primero) para que el Jefe/equipo sepa
# qué atender primero. Siempre se limita al departamento del usuario
# que hace la petición (nunca recibe id_departamento por parámetro) Y
# ahora también al proyecto indicado — Department es un catálogo
# GLOBAL (no tiene id_project, ver department_model.py), así que sin
# este filtro el mismo departamento traería pendientes de desglose de
# TODOS los proyectos donde ese departamento se usa.
def get_pendientes_mi_departamento(id_project: str, db: Session, current_user: dict):
    id_departamento = _get_user_departamento(current_user, db)

    if not id_departamento:
        return api_response(False, "Tu usuario no tiene un departamento asignado")

    orden_prioridad = {"alta": 0, "media": 1, "baja": 2, None: 3}

    pendientes = db.query(DesgloseItemDetalle).join(
        DesgloseItem, DesgloseItemDetalle.id_desglose_item == DesgloseItem.id_desglose_item
    ).join(
        Scene, DesgloseItem.id_escena == Scene.id_escena
    ).join(
        Script, Scene.id_guion == Script.id_guion
    ).filter(
        DesgloseItem.id_departamento == id_departamento,
        DesgloseItemDetalle.estado != "completado",
        Script.id_project == id_project,
    ).all()

    pendientes.sort(key=lambda d: orden_prioridad.get(d.prioridad, 3))

    resultado = []
    for d in pendientes:
        item = db.query(DesgloseItem).filter(DesgloseItem.id_desglose_item == d.id_desglose_item).first()
        fila = _serialize_detalle(d)
        fila["categoria"] = item.categoria if item else None
        fila["nombre_item"] = item.nombre_item if item else None
        fila["id_escena"] = item.id_escena if item else None
        resultado.append(fila)

    return api_response(True, "Pendientes de tu departamento", resultado)
