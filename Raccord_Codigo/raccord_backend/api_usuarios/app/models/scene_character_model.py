from sqlalchemy import Column, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# SCENE CHARACTER MODEL (tabla "escenas_personajes")
# ==========================================
# Tabla de relación pura: qué personajes aparecen en qué escena (el
# "cast" de cada escena). Llave primaria compuesta (id_escena,
# id_personaje), igual que en la BD. Ambas FK son ON DELETE CASCADE en
# Postgres — borrar la escena o el personaje se lleva el vínculo, pero
# eso es justamente lo esperado en una tabla de relación (no borra al
# personaje ni a la escena en sí).
class SceneCharacter(Base):
    __tablename__ = "escenas_personajes"

    id_escena = Column(
        UUID(as_uuid=True),
        ForeignKey("escenas.id_escena", ondelete="CASCADE"),
        primary_key=True
    )

    id_personaje = Column(
        UUID(as_uuid=True),
        ForeignKey("personajes.id_personaje", ondelete="CASCADE"),
        primary_key=True
    )
