from sqlalchemy.orm import Session

from app.models.breakdown_sheet_model import BreakdownSheet
from app.models.scene_model import Scene
from app.models.breakdown_model import DesgloseItem

from app.schemas.breakdown_sheet_schema import BreakdownSheetSchema

from app.utils.response import api_response


# ==========================================
# SERIALIZAR DESGLOSE (CONTENEDOR)
# ==========================================
def _serialize(d: BreakdownSheet):
    return {
        "id_desglose": d.id_desglose,
        "version": d.version,
        "semana_grabacion": d.semana_grabacion,
        "dia_rodaje": d.dia_rodaje,
        "hora_inicio": str(d.hora_inicio) if d.hora_inicio else None,
        "hora_fin": str(d.hora_fin) if d.hora_fin else None,
        "location": d.location,
        "requerimientos": d.requerimientos,
        "activo": d.activo,
        "id_project": d.id_project,
    }


def _serialize_scene(s: Scene):
    return {
        "id_escena": s.id_escena,
        "numero_de_escena": s.numero_de_escena,
        "encabezado": s.encabezado,
        "descripcion": s.descripcion,
        "modo_vista": s.modo_vista,
        "momento_dia": s.momento_dia,
        "ciudad": s.ciudad,
        "pagina": s.pagina,
        "dia_dramatico": s.dia_dramatico,
    }


def _serialize_item(i: DesgloseItem):
    return {
        "id_desglose_item": i.id_desglose_item,
        "id_escena": i.id_escena,
        "id_departamento": i.id_departamento,
        "categoria": i.categoria,
        "nombre_item": i.nombre_item,
        "cantidad": i.cantidad,
    }


# ==========================================
# GET ALL BREAKDOWN SHEETS
# ==========================================
def get_breakdown_sheets(id_project: str, db: Session):
    sheets = (
        db.query(BreakdownSheet)
        .filter(BreakdownSheet.id_project == id_project)
        .order_by(BreakdownSheet.semana_grabacion, BreakdownSheet.dia_rodaje)
        .all()
    )

    return api_response(True, "Lista de desgloses", [_serialize(d) for d in sheets])


# ==========================================
# GET BREAKDOWN SHEET BY ID
# ==========================================
# Igual que con plan_rodaje: el contenido real es sobre todo lo que ya
# está en escenas (escenas.id_desglose), y el desglose general por
# categoría que ya se haya cargado en desglose_items para esas escenas
# (app/models/breakdown_model.py). "requerimientos" queda como el
# resumen libre que trae la tabla original.
def get_breakdown_sheet(id: str, db: Session):
    sheet = db.query(BreakdownSheet).filter(BreakdownSheet.id_desglose == id).first()

    if not sheet:
        return api_response(False, "Desglose no encontrado")

    scenes = db.query(Scene).filter(Scene.id_desglose == id).order_by(Scene.id_escena).all()
    id_escenas = [s.id_escena for s in scenes]

    items = []
    if id_escenas:
        items = db.query(DesgloseItem).filter(DesgloseItem.id_escena.in_(id_escenas)).all()

    data = _serialize(sheet)
    data["escenas"] = [_serialize_scene(s) for s in scenes]
    data["items_generales"] = [_serialize_item(i) for i in items]

    return api_response(True, "Desglose encontrado", data)


# ==========================================
# CREATE BREAKDOWN SHEET
# ==========================================
# No se manda id_desglose: lo genera la BD ('desg' + consecutivo).
def create_breakdown_sheet(sheet: BreakdownSheetSchema, db: Session):
    new_sheet = BreakdownSheet(
        version=sheet.version,
        semana_grabacion=sheet.semana_grabacion,
        dia_rodaje=sheet.dia_rodaje,
        hora_inicio=sheet.hora_inicio,
        hora_fin=sheet.hora_fin,
        location=sheet.location,
        requerimientos=sheet.requerimientos,
        activo=sheet.activo if sheet.activo is not None else True,
        id_project=sheet.id_project,
    )

    db.add(new_sheet)
    db.commit()
    db.refresh(new_sheet)

    return api_response(True, "Desglose creado", _serialize(new_sheet))


# ==========================================
# UPDATE BREAKDOWN SHEET (PUT - completo)
# ==========================================
# NOTA: BreakdownSheetSchema trae id_project (mismo schema que create),
# pero a propósito NO se copia acá — ver la misma nota en
# character_controller.py.
def update_breakdown_sheet_full(id: str, sheet: BreakdownSheetSchema, db: Session):
    sheet_db = db.query(BreakdownSheet).filter(BreakdownSheet.id_desglose == id).first()

    if not sheet_db:
        return api_response(False, "Desglose no encontrado")

    sheet_db.version = sheet.version
    sheet_db.semana_grabacion = sheet.semana_grabacion
    sheet_db.dia_rodaje = sheet.dia_rodaje
    sheet_db.hora_inicio = sheet.hora_inicio
    sheet_db.hora_fin = sheet.hora_fin
    sheet_db.location = sheet.location
    sheet_db.requerimientos = sheet.requerimientos
    sheet_db.activo = sheet.activo if sheet.activo is not None else True

    db.commit()
    db.refresh(sheet_db)

    return api_response(True, "Desglose actualizado", _serialize(sheet_db))


# ==========================================
# UPDATE BREAKDOWN SHEET (PATCH - parcial)
# ==========================================
def update_breakdown_sheet(id: str, sheet, db: Session):
    sheet_db = db.query(BreakdownSheet).filter(BreakdownSheet.id_desglose == id).first()

    if not sheet_db:
        return api_response(False, "Desglose no encontrado")

    update_data = sheet.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(sheet_db, key, value)

    db.commit()
    db.refresh(sheet_db)

    return api_response(True, "Desglose actualizado", _serialize(sheet_db))


# ==========================================
# DELETE BREAKDOWN SHEET
# ==========================================
# escenas.id_desglose tiene FK ON DELETE CASCADE hacia desgloses.
# Igual que en plan_rodaje, se bloquea si todavía hay escenas
# asociadas para no borrarlas en cascada sin querer.
def delete_breakdown_sheet(id: str, db: Session):
    sheet = db.query(BreakdownSheet).filter(BreakdownSheet.id_desglose == id).first()

    if not sheet:
        return api_response(False, "Desglose no encontrado")

    scenes_count = db.query(Scene).filter(Scene.id_desglose == id).count()

    if scenes_count > 0:
        return api_response(
            False,
            f"No se puede eliminar: hay {scenes_count} escena(s) asociadas a este desglose",
            error="BREAKDOWN_SHEET_IN_USE"
        )

    db.delete(sheet)
    db.commit()

    return api_response(True, "Desglose eliminado")
