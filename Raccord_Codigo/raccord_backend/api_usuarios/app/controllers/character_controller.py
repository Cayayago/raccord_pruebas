from sqlalchemy.orm import Session

from app.models.character_model import Character
from app.models.actor_model import Actor
from app.models.scene_character_model import SceneCharacter

from app.schemas.character_schema import CharacterSchema

from app.utils.response import api_response


# ==========================================
# SERIALIZAR PERSONAJE
# ==========================================
def _serialize(c: Character):
    return {
        "id_personaje": c.id_personaje,
        "nombre": c.nombre,
        "edad": c.edad,
        "codigo_personaje": c.codigo_personaje,
        "id_project": c.id_project,
    }


def _serialize_actor(a: Actor):
    return {
        "id_actor": a.id_actor,
        "nombre": a.nombre,
        "apellido": a.apellido,
        "genero": a.genero,
    }


# ==========================================
# GET ALL CHARACTERS (de UN proyecto)
# ==========================================
# Antes traía TODOS los personajes de TODOS los proyectos, de
# cualquier cliente — sin ningún filtro. Ahora exige id_project y solo
# devuelve los de ese proyecto (el permiso/pertenencia ya se validó en
# la ruta, ver require_project_member en character_routes.py).
def get_characters(id_project: str, db: Session):
    characters = (
        db.query(Character)
        .filter(Character.id_project == id_project)
        .order_by(Character.id_personaje)
        .all()
    )
    return api_response(True, "Lista de personajes", [_serialize(c) for c in characters])


# ==========================================
# GET CHARACTER BY ID
# ==========================================
# Trae también los actores ya asignados a este personaje (actors.id_personaje),
# para no tener que hacer una segunda llamada aparte.
def get_character(id: str, db: Session):
    character = db.query(Character).filter(Character.id_personaje == id).first()

    if not character:
        return api_response(False, "Personaje no encontrado")

    actors = db.query(Actor).filter(Actor.id_personaje == id).all()

    data = _serialize(character)
    data["actores"] = [_serialize_actor(a) for a in actors]

    return api_response(True, "Personaje encontrado", data)


# ==========================================
# CREATE CHARACTER
# ==========================================
# No se manda id_personaje: lo genera el trigger de la BD (cast1, cast2, ...).
# La pertenencia al proyecto (character.id_project) y el permiso ya se
# validaron en la ruta antes de llegar acá (ver character_routes.py).
def create_character(character: CharacterSchema, db: Session):
    new_character = Character(
        nombre=character.nombre,
        edad=character.edad,
        codigo_personaje=character.codigo_personaje,
        id_project=character.id_project,
    )

    db.add(new_character)
    db.commit()
    db.refresh(new_character)

    return api_response(True, "Personaje creado", _serialize(new_character))


# ==========================================
# UPDATE CHARACTER (PUT - completo)
# ==========================================
# NOTA: CharacterSchema (mismo schema que create) trae id_project, pero
# a propósito NO se copia acá — mover un personaje de proyecto por un
# PUT normal sería una forma fácil de saltarse el aislamiento por
# proyecto. El proyecto de un personaje queda fijo desde su creación.
def update_character_full(id: str, character: CharacterSchema, db: Session):
    character_db = db.query(Character).filter(Character.id_personaje == id).first()

    if not character_db:
        return api_response(False, "Personaje no encontrado")

    character_db.nombre = character.nombre
    character_db.edad = character.edad
    character_db.codigo_personaje = character.codigo_personaje

    db.commit()
    db.refresh(character_db)

    return api_response(True, "Personaje actualizado", _serialize(character_db))


# ==========================================
# UPDATE CHARACTER (PATCH - parcial)
# ==========================================
def update_character(id: str, character, db: Session):
    character_db = db.query(Character).filter(Character.id_personaje == id).first()

    if not character_db:
        return api_response(False, "Personaje no encontrado")

    update_data = character.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(character_db, key, value)

    db.commit()
    db.refresh(character_db)

    return api_response(True, "Personaje actualizado", _serialize(character_db))


# ==========================================
# DELETE CHARACTER
# ==========================================
# En la BD, actors.id_personaje tiene FK ON DELETE CASCADE hacia
# personajes: sin este guard, borrar un personaje borraría también a
# los actores asignados a él (su ficha completa: medidas, alergias,
# etc.), no solo el vínculo. Se bloquea si hay actores asignados,
# igual que departments/guiones con sus respectivas dependencias.
#
# escenas_personajes.id_personaje también es ON DELETE CASCADE, pero
# esa sí es solo una tabla de relación (el vínculo del cast en cada
# escena) — no hace falta bloquear por eso, solo se informa cuántas
# escenas perderían a este personaje en su cast.
def delete_character(id: str, db: Session):
    character = db.query(Character).filter(Character.id_personaje == id).first()

    if not character:
        return api_response(False, "Personaje no encontrado")

    actors_count = db.query(Actor).filter(Actor.id_personaje == id).count()

    if actors_count > 0:
        return api_response(
            False,
            f"No se puede eliminar: hay {actors_count} actor(es) asignado(s) a este personaje",
            error="CHARACTER_HAS_ACTORS"
        )

    scenes_count = db.query(SceneCharacter).filter(SceneCharacter.id_personaje == id).count()

    db.delete(character)
    db.commit()

    mensaje = "Personaje eliminado"
    if scenes_count > 0:
        mensaje += f" (también se quitó del cast de {scenes_count} escena(s))"

    return api_response(True, mensaje)
