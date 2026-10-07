from sqlalchemy.orm import Session

from app.models.scene_model import Scene
from app.models.script_model import Script
from app.models.scene_character_model import SceneCharacter
from app.models.character_model import Character

from app.schemas.scene_schema import SceneSchema

from app.utils.response import api_response


# ==========================================
# SERIALIZAR PERSONAJE (para el cast embebido) — mismo shape que
# scene_character_controller._serialize_character, para que el frontend
# pueda reusar el mismo parseo sin importar de qué endpoint vino.
# ==========================================
def _serialize_character(c: Character):
    return {
        "id_personaje": c.id_personaje,
        "nombre": c.nombre,
        "edad": c.edad,
        "codigo_personaje": c.codigo_personaje,
    }


# ==========================================
# SERIALIZAR ESCENA
# ==========================================
# `cast`: lista de personajes ya resuelta por el caller (ver get_scenes),
# o None si no se pidió (endpoints que no la necesitan no pagan el costo
# de la query extra). Cuando es None, la clave "cast" ni siquiera se
# incluye, para no cambiar el shape que ya consumían otros lugares.
def _serialize(s: Scene, cast: list | None = None):
    data = {
        "id_escena": s.id_escena,
        "numero_de_escena": s.numero_de_escena,
        "encabezado": s.encabezado,
        "descripcion": s.descripcion,
        "id_guion": s.id_guion,
        "modo_vista": s.modo_vista,
        "momento_dia": s.momento_dia,
        "ciudad": s.ciudad,
        "pagina": s.pagina,
        "fecha_de_grabacion": str(s.fecha_de_grabacion) if s.fecha_de_grabacion else None,
        "dia_dramatico": s.dia_dramatico,
        "id_rodaje": s.id_rodaje,
        "id_desglose": s.id_desglose,
        "estado": s.estado,
        "locacion_rodaje": s.locacion_rodaje,
        "tiempo_estimado": s.tiempo_estimado,
        "hora_inicio_rodaje": str(s.hora_inicio_rodaje) if s.hora_inicio_rodaje else None,
        "notas_rodaje": s.notas_rodaje,
        "orden_rodaje": s.orden_rodaje,
        "bloque_grabacion": s.bloque_grabacion,
        "comentarios": s.comentarios
    }
    if cast is not None:
        data["cast"] = cast
    return data


# ==========================================
# GET ALL SCENES (de UN proyecto)
# ==========================================
# Antes traía las escenas de TODOS los proyectos sin filtro. Scene no
# tiene columna id_project propia (ver scene_model.py) — se resuelve
# subiendo por escenas.id_guion -> guiones.id_project.
def get_scenes(id_project: str, db: Session):
    scenes = (
        db.query(Scene)
        .join(Script, Scene.id_guion == Script.id_guion)
        .filter(Script.id_project == id_project)
        .order_by(Scene.id_escena)
        .all()
    )

    # Cast de TODAS las escenas en 2 consultas (en vez de que el
    # frontend dispare un GET /scenes/{id}/cast POR escena). Con ~129
    # escenas en un proyecto real, eso eran ~129 peticiones HTTP
    # "paralelas" pero en la práctica servidas en oleadas por el límite
    # de conexiones concurrentes del cliente — muy lento en la red real
    # de un dispositivo físico (Plan de Rodaje tardaba decenas de
    # segundos en cargar). Ver shooting_days_screen.dart, que ahora usa
    # este campo embebido en vez de ese prefetch por escena.
    cast_by_scene: dict[str, list] = {}
    scene_ids = [s.id_escena for s in scenes]
    if scene_ids:
        links = db.query(SceneCharacter).filter(SceneCharacter.id_escena.in_(scene_ids)).all()
        character_ids = list({link.id_personaje for link in links})
        characters_by_id = {}
        if character_ids:
            characters = db.query(Character).filter(Character.id_personaje.in_(character_ids)).all()
            characters_by_id = {c.id_personaje: c for c in characters}
        for link in links:
            character = characters_by_id.get(link.id_personaje)
            if character:
                cast_by_scene.setdefault(link.id_escena, []).append(_serialize_character(character))

    return api_response(True, "Lista de escenas", [_serialize(s, cast_by_scene.get(s.id_escena, [])) for s in scenes])


# ==========================================
# GET SCENE BY ID
# ==========================================
def get_scene(id: str, db: Session):
    scene = db.query(Scene).filter(Scene.id_escena == id).first()

    if not scene:
        return api_response(False, "Escena no encontrada")

    return api_response(True, "Escena encontrada", _serialize(scene))


# ==========================================
# GET SCENES BY SCRIPT (GUION)
# ==========================================
def get_scenes_by_script(id_guion: str, db: Session):
    scenes = db.query(Scene).filter(Scene.id_guion == id_guion).order_by(Scene.id_escena).all()
    return api_response(True, "Escenas del guion", [_serialize(s) for s in scenes])


# ==========================================
# GET SCENES BY SHOOTING DAY (PLAN DE RODAJE)
# ==========================================
def get_scenes_by_rodaje(id_rodaje: str, db: Session):
    scenes = db.query(Scene).filter(Scene.id_rodaje == id_rodaje).order_by(Scene.id_escena).all()
    return api_response(True, "Escenas del día de rodaje", [_serialize(s) for s in scenes])


# ==========================================
# GET SCENES BY BREAKDOWN SHEET (DESGLOSE)
# ==========================================
def get_scenes_by_desglose(id_desglose: str, db: Session):
    scenes = db.query(Scene).filter(Scene.id_desglose == id_desglose).order_by(Scene.id_escena).all()
    return api_response(True, "Escenas del desglose", [_serialize(s) for s in scenes])


# ==========================================
# CREATE SCENE
# ==========================================
# id_guion es obligatorio EN LA PRÁCTICA aunque el schema lo marque
# opcional (compatibilidad con datos viejos): sin un guion no hay forma
# de resolver a qué proyecto pertenece la escena, y eso rompería el
# aislamiento por proyecto. El permiso ya se validó en la ruta contra
# el proyecto del guion (ver scene_routes.py) antes de llegar acá.
def create_scene(scene: SceneSchema, db: Session):
    if not scene.id_guion:
        return api_response(False, "id_guion es obligatorio para crear una escena", error="MISSING_SCRIPT")

    new_scene = Scene(
        numero_de_escena=scene.numero_de_escena,
        encabezado=scene.encabezado,
        descripcion=scene.descripcion,
        id_guion=scene.id_guion,
        modo_vista=scene.modo_vista,
        momento_dia=scene.momento_dia,
        ciudad=scene.ciudad,
        pagina=scene.pagina,
        fecha_de_grabacion=scene.fecha_de_grabacion,
        dia_dramatico=scene.dia_dramatico,
        id_rodaje=scene.id_rodaje,
        id_desglose=scene.id_desglose,
        estado=scene.estado or "Pendiente",
        locacion_rodaje=scene.locacion_rodaje,
        tiempo_estimado=scene.tiempo_estimado,
        hora_inicio_rodaje=scene.hora_inicio_rodaje,
        notas_rodaje=scene.notas_rodaje,
        orden_rodaje=scene.orden_rodaje,
        bloque_grabacion=scene.bloque_grabacion,
        comentarios=scene.comentarios
    )

    db.add(new_scene)
    db.commit()
    db.refresh(new_scene)

    return api_response(True, "Escena creada", _serialize(new_scene))


# ==========================================
# UPDATE SCENE (PUT - completo)
# ==========================================
# NOTA DE SEGURIDAD: scene.id_guion SÍ se copia (a diferencia de
# id_project en los otros controllers) porque reasignar una escena a
# otro guion DEL MISMO proyecto es un caso de uso legítimo. Lo que no
# se permite es mover la escena a un guion de OTRO proyecto (eso
# evadiría el aislamiento) — se bloquea explícitamente abajo.
def update_scene_full(id: str, scene: SceneSchema, db: Session):
    scene_db = db.query(Scene).filter(Scene.id_escena == id).first()

    if not scene_db:
        return api_response(False, "Escena no encontrada")

    if scene.id_guion and scene.id_guion != str(scene_db.id_guion):
        proyecto_actual = (
            db.query(Script.id_project).filter(Script.id_guion == scene_db.id_guion).scalar()
            if scene_db.id_guion else None
        )
        proyecto_nuevo = db.query(Script.id_project).filter(Script.id_guion == scene.id_guion).scalar()
        if proyecto_nuevo != proyecto_actual:
            return api_response(
                False,
                "No se puede mover una escena a un guion de otro proyecto",
                error="CROSS_PROJECT_MOVE",
            )

    scene_db.numero_de_escena = scene.numero_de_escena
    scene_db.encabezado = scene.encabezado
    scene_db.descripcion = scene.descripcion
    scene_db.id_guion = scene.id_guion
    scene_db.modo_vista = scene.modo_vista
    scene_db.momento_dia = scene.momento_dia
    scene_db.ciudad = scene.ciudad
    scene_db.pagina = scene.pagina
    scene_db.fecha_de_grabacion = scene.fecha_de_grabacion
    scene_db.dia_dramatico = scene.dia_dramatico
    scene_db.id_rodaje = scene.id_rodaje
    scene_db.id_desglose = scene.id_desglose
    scene_db.estado = scene.estado or scene_db.estado
    scene_db.locacion_rodaje = scene.locacion_rodaje
    scene_db.tiempo_estimado = scene.tiempo_estimado
    scene_db.hora_inicio_rodaje = scene.hora_inicio_rodaje
    scene_db.notas_rodaje = scene.notas_rodaje
    scene_db.orden_rodaje = scene.orden_rodaje
    scene_db.bloque_grabacion = scene.bloque_grabacion
    scene_db.comentarios = scene.comentarios

    db.commit()
    db.refresh(scene_db)

    return api_response(True, "Escena actualizada", _serialize(scene_db))


# ==========================================
# UPDATE SCENE (PATCH - parcial)
# ==========================================
def update_scene(id: str, scene, db: Session):
    scene_db = db.query(Scene).filter(Scene.id_escena == id).first()

    if not scene_db:
        return api_response(False, "Escena no encontrada")

    update_data = scene.model_dump(exclude_unset=True)

    # Mismo guard que en update_scene_full: no se puede mover la escena
    # a un guion de otro proyecto.
    if update_data.get("id_guion") and update_data["id_guion"] != str(scene_db.id_guion):
        proyecto_actual = (
            db.query(Script.id_project).filter(Script.id_guion == scene_db.id_guion).scalar()
            if scene_db.id_guion else None
        )
        proyecto_nuevo = db.query(Script.id_project).filter(Script.id_guion == update_data["id_guion"]).scalar()
        if proyecto_nuevo != proyecto_actual:
            return api_response(
                False,
                "No se puede mover una escena a un guion de otro proyecto",
                error="CROSS_PROJECT_MOVE",
            )

    for key, value in update_data.items():
        setattr(scene_db, key, value)

    db.commit()
    db.refresh(scene_db)

    return api_response(True, "Escena actualizada", _serialize(scene_db))


# ==========================================
# DELETE SCENE
# ==========================================
# escenas_personajes.id_escena tiene FK ON DELETE CASCADE hacia
# escenas, pero es solo una tabla de relación (no borra personajes,
# solo el vínculo), así que no hace falta bloquear el borrado como se
# hizo con departamentos. Cuando exista el módulo de personajes, vale
# la pena revisar si conviene avisar cuántos vínculos se van a perder.
def delete_scene(id: str, db: Session):
    scene = db.query(Scene).filter(Scene.id_escena == id).first()

    if not scene:
        return api_response(False, "Escena no encontrada")

    db.delete(scene)
    db.commit()

    return api_response(True, "Escena eliminada")
