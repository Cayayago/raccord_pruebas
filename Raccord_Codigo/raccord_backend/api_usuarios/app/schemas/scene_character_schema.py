from pydantic import BaseModel


# ==========================================
# CAST DE UNA ESCENA (escenas_personajes)
# ==========================================
# Para agregar un personaje al cast de una escena. id_escena viene de
# la URL (POST /scenes/{id_escena}/cast), acá solo se manda el
# personaje a vincular.
class SceneCharacterSchema(BaseModel):
    id_personaje: str
