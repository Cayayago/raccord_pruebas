from sqlalchemy.orm import Session

from app.models.scene_character_model import SceneCharacter
from app.models.character_model import Character
from app.models.scene_model import Scene
from app.models.script_model import Script

from app.schemas.scene_character_schema import SceneCharacterSchema

from app.utils.response import api_response


def _serialize_character(c: Character):
    return {
        "id_personaje": c.id_personaje,
        "nombre": c.nombre,
        "edad": c.edad,
        "codigo_personaje": c.codigo_personaje,
    }


# ==========================================
# GET CAST DE UNA ESCENA
# ==========================================
def get_cast_by_scene(id_escena: str, db: Session):
    scene = db.query(Scene).filter(Scene.id_escena == id_escena).first()

    if not scene:
        return api_response(False, "Escena no encontrada")

    links = db.query(SceneCharacter).filter(SceneCharacter.id_escena == id_escena).all()
    id_personajes = [link.id_personaje for link in links]

    characters = []
    if id_personajes:
        characters = db.query(Character).filter(Character.id_personaje.in_(id_personajes)).all()

    return api_response(True, "Cast de la escena", [_serialize_character(c) for c in characters])


# ==========================================
# AGREGAR PERSONAJE AL CAST DE UNA ESCENA
# ==========================================
def add_character_to_scene(id_escena: str, data: SceneCharacterSchema, db: Session):
    scene = db.query(Scene).filter(Scene.id_escena == id_escena).first()

    if not scene:
        return api_response(False, "Escena no encontrada")

    character = db.query(Character).filter(Character.id_personaje == data.id_personaje).first()

    if not character:
        return api_response(False, "Personaje no encontrado")

    # No se puede meter al cast un personaje de OTRO proyecto, aunque
    # el usuario tenga permiso en el proyecto de la escena (ver la
    # misma preocupación resuelta con require_record_project_permission
    # en el resto del módulo).
    id_project_escena = (
        db.query(Script.id_project).filter(Script.id_guion == scene.id_guion).scalar()
        if scene.id_guion else None
    )
    if character.id_project != id_project_escena:
        return api_response(False, "Este personaje pertenece a otro proyecto", error="CROSS_PROJECT_CHARACTER")

    existing = db.query(SceneCharacter).filter(
        SceneCharacter.id_escena == id_escena,
        SceneCharacter.id_personaje == data.id_personaje
    ).first()

    if existing:
        return api_response(False, "Este personaje ya está en el cast de la escena", error="ALREADY_IN_CAST")

    link = SceneCharacter(id_escena=id_escena, id_personaje=data.id_personaje)
    db.add(link)
    db.commit()

    return api_response(True, "Personaje agregado al cast de la escena", {
        "id_escena": id_escena,
        "id_personaje": data.id_personaje
    })


# ==========================================
# QUITAR PERSONAJE DEL CAST DE UNA ESCENA
# ==========================================
def remove_character_from_scene(id_escena: str, id_personaje: str, db: Session):
    link = db.query(SceneCharacter).filter(
        SceneCharacter.id_escena == id_escena,
        SceneCharacter.id_personaje == id_personaje
    ).first()

    if not link:
        return api_response(False, "Este personaje no está en el cast de la escena")

    db.delete(link)
    db.commit()

    return api_response(True, "Personaje quitado del cast de la escena")
