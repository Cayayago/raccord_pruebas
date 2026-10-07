from pydantic import BaseModel
from typing import Optional, Literal
from datetime import date

# Debe coincidir exactamente con el ENUM "generosex" de la BD. El valor
# 'fenemino' es el que existe realmente en Postgres (typo original del
# esquema, no un error de este archivo) — si se manda 'femenino' bien
# escrito, Postgres lo rechaza porque no es un label válido del enum.
Genero = Literal["masculino", "fenemino", "otro"]

# Catálogos de seguimiento de casting (deben coincidir con
# kStatusConfirmacionActor/kCategoriasCast en models/character.dart).
StatusConfirmacion = Literal["Confirmado", "No confirmado"]
CategoriaCast = Literal["Principal", "Secundario", "Personal de Apoyo"]


# ==========================================
# ACTORS
# ==========================================
# id_actor no va en el schema de creación: lo genera el trigger de la
# base de datos (act1, act2, ...). id_personaje es opcional: un actor
# puede existir en el catálogo sin estar todavía asignado a un rol.
class ActorSchema(BaseModel):
    # Solo nombre/apellido son obligatorios de verdad — pedido explícito
    # del usuario (2026-09-03): poder guardar el actor con lo mínimo y
    # subir sus 2 fotos de inmediato (necesitan un id_actor real), y
    # completar el resto de la ficha técnica después. Ver
    # sql/020_actor_campos_opcionales.sql y actor_model.py.
    nombre: str
    apellido: str
    genero: Optional[Genero] = None
    fecha_de_nacimiento: Optional[date] = None

    talla_zapatos: Optional[str] = None
    ancho_espalda: Optional[str] = None
    pecho: Optional[str] = None
    cintura: Optional[str] = None
    cadera: Optional[str] = None
    largo_manga: Optional[str] = None
    largo_pierna: Optional[str] = None
    talla_anillo: Optional[str] = None
    contorno_cabeza: Optional[str] = None
    contorno_cuello: Optional[str] = None

    color_cabello: Optional[str] = None
    textura_cabello: Optional[str] = None
    tipo_piel: Optional[str] = None
    color_ojos: Optional[str] = None
    # Tono de piel: texto libre (no Literal) a propósito, igual que
    # tipo_piel/color_ojos — así el catálogo del frontend puede crecer
    # sin requerir migración de schema. Ver actor_model.py.
    tono_piel: Optional[str] = None

    alergias: Optional[str] = None
    habilidades_especiales: Optional[str] = None
    restricciones: Optional[str] = None
    comentarios_adicionales: Optional[str] = None

    nacionalidad: Optional[str] = None
    doble_riesgo: Optional[bool] = None

    id_personaje: Optional[str] = None
    # Obligatorio (ver sql/015_project_scoping.sql y CharacterSchema):
    # todo actor NUEVO debe quedar amarrado a un proyecto desde que se
    # crea, tenga o no personaje asignado todavía. No se puede cambiar
    # después (no está en ActorUpdateSchema).
    id_project: str

    # Contacto de producción + seguimiento de casting (ver actor_model.py
    # y sql/018_actor_contacto_casting.sql) — todos opcionales, no
    # forman parte de la ficha física del actor.
    cedula: Optional[str] = None
    direccion: Optional[str] = None
    telefono: Optional[str] = None
    correo: Optional[str] = None
    status_confirmacion: Optional[StatusConfirmacion] = None
    llamados: Optional[str] = None
    fechas_tentativas: Optional[str] = None
    guion_enviado: Optional[bool] = None
    ensayos: Optional[str] = None
    categoria_cast: Optional[CategoriaCast] = None


class ActorUpdateSchema(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    genero: Optional[Genero] = None
    fecha_de_nacimiento: Optional[date] = None

    talla_zapatos: Optional[str] = None
    ancho_espalda: Optional[str] = None
    pecho: Optional[str] = None
    cintura: Optional[str] = None
    cadera: Optional[str] = None
    largo_manga: Optional[str] = None
    largo_pierna: Optional[str] = None
    talla_anillo: Optional[str] = None
    contorno_cabeza: Optional[str] = None
    contorno_cuello: Optional[str] = None

    color_cabello: Optional[str] = None
    textura_cabello: Optional[str] = None
    tipo_piel: Optional[str] = None
    color_ojos: Optional[str] = None
    tono_piel: Optional[str] = None

    alergias: Optional[str] = None
    habilidades_especiales: Optional[str] = None
    restricciones: Optional[str] = None
    comentarios_adicionales: Optional[str] = None

    nacionalidad: Optional[str] = None
    doble_riesgo: Optional[bool] = None

    id_personaje: Optional[str] = None

    cedula: Optional[str] = None
    direccion: Optional[str] = None
    telefono: Optional[str] = None
    correo: Optional[str] = None
    status_confirmacion: Optional[StatusConfirmacion] = None
    llamados: Optional[str] = None
    fechas_tentativas: Optional[str] = None
    guion_enviado: Optional[bool] = None
    ensayos: Optional[str] = None
    categoria_cast: Optional[CategoriaCast] = None
