"""Validaciones de los schemas de producción: actores, desglose, plan de rodaje."""
from datetime import time

import pytest
from pydantic import ValidationError

from app.schemas.actor_schema import ActorSchema, ActorUpdateSchema
from app.schemas.breakdown_schema import (
    DesgloseDetalleSchema,
    DesgloseDetalleUpdateSchema,
    DesgloseItemSchema,
    DesgloseItemUpdateSchema,
)
from app.schemas.breakdown_sheet_schema import BreakdownSheetSchema, BreakdownSheetUpdateSchema
from app.schemas.shooting_day_schema import ShootingDaySchema, ShootingDayUpdateSchema


# ------------------------------------------------ actores
def test_actor_solo_exige_nombre_apellido_y_proyecto():
    a = ActorSchema(nombre="Ana", apellido="Ruiz", id_project="p1")
    assert a.genero is None and a.doble_riesgo is None


@pytest.mark.parametrize("faltante", ["nombre", "apellido", "id_project"])
def test_actor_sin_campo_obligatorio_es_rechazado(faltante):
    datos = dict(nombre="Ana", apellido="Ruiz", id_project="p1")
    datos.pop(faltante)
    with pytest.raises(ValidationError):
        ActorSchema(**datos)


@pytest.mark.parametrize("genero", ["masculino", "fenemino", "otro"])
def test_generos_validos_incluyen_el_valor_real_del_enum_de_bd(genero):
    # 'fenemino' (sic) es el label real del ENUM en Postgres.
    assert ActorUpdateSchema(genero=genero).genero == genero


def test_genero_bien_escrito_no_coincide_con_el_enum_de_bd():
    with pytest.raises(ValidationError):
        ActorUpdateSchema(genero="femenino")


@pytest.mark.parametrize("estado", ["Confirmado", "No confirmado"])
def test_status_de_confirmacion_valido(estado):
    assert ActorUpdateSchema(status_confirmacion=estado).status_confirmacion == estado


@pytest.mark.parametrize("categoria", ["Principal", "Secundario", "Personal de Apoyo"])
def test_categoria_de_cast_valida(categoria):
    assert ActorUpdateSchema(categoria_cast=categoria).categoria_cast == categoria


def test_categoria_de_cast_invalida():
    with pytest.raises(ValidationError):
        ActorUpdateSchema(categoria_cast="Protagonista")


def test_actor_no_permite_cambiar_de_proyecto_en_la_actualizacion():
    assert "id_project" not in ActorUpdateSchema.model_fields


# ------------------------------------------------ desglose
CATEGORIAS = [
    "Props", "Extras", "Bits", "SFX", "Sonido", "Stunts", "Vestuario", "Maquillaje/Pelo",
    "Maquillaje FX", "Cámara", "VFX", "Armas", "Vehículos", "Animales", "Arte", "Música",
    "Crew Adicional", "Notas",
]


@pytest.mark.parametrize("categoria", CATEGORIAS)
def test_categorias_de_desglose_validas(categoria):
    assert DesgloseItemSchema(id_escena="e1", categoria=categoria, nombre_item="x").categoria == categoria


@pytest.mark.parametrize("categoria", ["Cast", "props", "", "Utilería"])
def test_cast_no_es_categoria_de_desglose(categoria):
    with pytest.raises(ValidationError):
        DesgloseItemSchema(id_escena="e1", categoria=categoria, nombre_item="x")


def test_item_de_desglose_exige_escena_categoria_y_nombre():
    with pytest.raises(ValidationError):
        DesgloseItemSchema(categoria="Props", nombre_item="x")
    DesgloseItemUpdateSchema()  # en actualización todo es opcional


def test_detalle_de_desglose_nace_pendiente():
    assert DesgloseDetalleSchema(etiqueta="mujeres").estado == "pendiente"


@pytest.mark.parametrize("estado", ["pendiente", "en_progreso", "completado"])
def test_estados_de_detalle_validos(estado):
    assert DesgloseDetalleUpdateSchema(estado=estado).estado == estado


def test_estado_de_detalle_invalido():
    with pytest.raises(ValidationError):
        DesgloseDetalleUpdateSchema(estado="terminado")


@pytest.mark.parametrize("prioridad", ["alta", "media", "baja"])
def test_prioridades_validas(prioridad):
    assert DesgloseDetalleSchema(etiqueta="x", prioridad=prioridad).prioridad == prioridad


def test_prioridad_invalida():
    with pytest.raises(ValidationError):
        DesgloseDetalleSchema(etiqueta="x", prioridad="urgente")


# ------------------------------------------------ plan de rodaje / contenedor de desglose
def test_dia_de_rodaje_activo_por_defecto_y_horas_tipadas():
    d = ShootingDaySchema(version="1", hora_inicio="07:30", id_project="p1")
    assert d.activo is True and d.hora_inicio == time(7, 30)


def test_hora_invalida_es_rechazada():
    with pytest.raises(ValidationError):
        ShootingDaySchema(version="1", hora_inicio="25:99", id_project="p1")


def test_dia_de_rodaje_exige_proyecto_y_no_permite_cambiarlo_despues():
    with pytest.raises(ValidationError):
        ShootingDaySchema(version="1")
    assert "id_project" not in ShootingDayUpdateSchema.model_fields


def test_contenedor_de_desglose_exige_requerimientos_y_proyecto():
    BreakdownSheetSchema(version="1", requerimientos="grúa", id_project="p1")
    with pytest.raises(ValidationError):
        BreakdownSheetSchema(version="1", id_project="p1")
    assert "id_project" not in BreakdownSheetUpdateSchema.model_fields
