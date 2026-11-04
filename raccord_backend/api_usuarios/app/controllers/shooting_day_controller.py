from sqlalchemy.orm import Session

from app.models.shooting_day_model import ShootingDay
from app.models.scene_model import Scene

from app.schemas.shooting_day_schema import ShootingDaySchema

from app.utils.response import api_response


# ==========================================
# SERIALIZAR DIA DE RODAJE
# ==========================================
def _serialize(r: ShootingDay):
    return {
        "id_rodaje": r.id_rodaje,
        "version": r.version,
        "semana_grabacion": r.semana_grabacion,
        "dia_rodaje": r.dia_rodaje,
        "hora_inicio": str(r.hora_inicio) if r.hora_inicio else None,
        "hora_fin": str(r.hora_fin) if r.hora_fin else None,
        "location": r.location,
        "notas": r.notas,
        "activo": r.activo,
        "id_project": r.id_project,
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


# ==========================================
# GET ALL SHOOTING DAYS
# ==========================================
def get_shooting_days(id_project: str, db: Session):
    days = (
        db.query(ShootingDay)
        .filter(ShootingDay.id_project == id_project)
        .order_by(ShootingDay.semana_grabacion, ShootingDay.dia_rodaje)
        .all()
    )

    return api_response(True, "Lista del plan de rodaje", [_serialize(r) for r in days])


# ==========================================
# GET SHOOTING DAY BY ID
# ==========================================
# La gran mayoría del contenido "real" de un día de rodaje son sus
# escenas (numero, INT/EXT, day/night, páginas, etc. — el stripboard),
# así que además de los campos propios del día se devuelve la lista de
# escenas agendadas ese día (escenas.id_rodaje).
def get_shooting_day(id: str, db: Session):
    day = db.query(ShootingDay).filter(ShootingDay.id_rodaje == id).first()

    if not day:
        return api_response(False, "Día de rodaje no encontrado")

    scenes = db.query(Scene).filter(Scene.id_rodaje == id).order_by(Scene.id_escena).all()

    data = _serialize(day)
    data["escenas"] = [_serialize_scene(s) for s in scenes]

    return api_response(True, "Día de rodaje encontrado", data)


# ==========================================
# CREATE SHOOTING DAY
# ==========================================
# No se manda id_rodaje: lo genera la BD ('rod' + consecutivo).
def create_shooting_day(day: ShootingDaySchema, db: Session):
    new_day = ShootingDay(
        version=day.version,
        semana_grabacion=day.semana_grabacion,
        dia_rodaje=day.dia_rodaje,
        hora_inicio=day.hora_inicio,
        hora_fin=day.hora_fin,
        location=day.location,
        notas=day.notas,
        activo=day.activo if day.activo is not None else True,
        id_project=day.id_project,
    )

    db.add(new_day)
    db.commit()
    db.refresh(new_day)

    return api_response(True, "Día de rodaje creado", _serialize(new_day))


# ==========================================
# UPDATE SHOOTING DAY (PUT - completo)
# ==========================================
# NOTA: ShootingDaySchema trae id_project (mismo schema que create),
# pero a propósito NO se copia acá — ver la misma nota en
# character_controller.py.
def update_shooting_day_full(id: str, day: ShootingDaySchema, db: Session):
    day_db = db.query(ShootingDay).filter(ShootingDay.id_rodaje == id).first()

    if not day_db:
        return api_response(False, "Día de rodaje no encontrado")

    day_db.version = day.version
    day_db.semana_grabacion = day.semana_grabacion
    day_db.dia_rodaje = day.dia_rodaje
    day_db.hora_inicio = day.hora_inicio
    day_db.hora_fin = day.hora_fin
    day_db.location = day.location
    day_db.notas = day.notas
    day_db.activo = day.activo if day.activo is not None else True

    db.commit()
    db.refresh(day_db)

    return api_response(True, "Día de rodaje actualizado", _serialize(day_db))


# ==========================================
# UPDATE SHOOTING DAY (PATCH - parcial)
# ==========================================
def update_shooting_day(id: str, day, db: Session):
    day_db = db.query(ShootingDay).filter(ShootingDay.id_rodaje == id).first()

    if not day_db:
        return api_response(False, "Día de rodaje no encontrado")

    update_data = day.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(day_db, key, value)

    db.commit()
    db.refresh(day_db)

    return api_response(True, "Día de rodaje actualizado", _serialize(day_db))


# ==========================================
# DELETE SHOOTING DAY
# ==========================================
# En la BD, escenas.id_rodaje tiene FK ON DELETE CASCADE hacia
# plan_rodaje. Sin este guard, borrar un día de rodaje desprogramaría
# (borraría) todas las escenas que tenía agendadas. Igual que en
# departments/guiones, se bloquea si todavía hay escenas asociadas.
def delete_shooting_day(id: str, db: Session):
    day = db.query(ShootingDay).filter(ShootingDay.id_rodaje == id).first()

    if not day:
        return api_response(False, "Día de rodaje no encontrado")

    scenes_count = db.query(Scene).filter(Scene.id_rodaje == id).count()

    if scenes_count > 0:
        return api_response(
            False,
            f"No se puede eliminar: hay {scenes_count} escena(s) agendadas en este día de rodaje",
            error="SHOOTING_DAY_IN_USE"
        )

    db.delete(day)
    db.commit()

    return api_response(True, "Día de rodaje eliminado")
