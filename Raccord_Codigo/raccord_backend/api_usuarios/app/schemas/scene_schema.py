from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import date, time
from uuid import UUID

# Deben coincidir exactamente con los catálogos del frontend
# (kModosVista/kMomentosDia/kEstadosEscena en models/scene.dart) — ya no
# son ENUM reales de Postgres (ver comentario en scene_model.py), la
# columna es texto libre y esta validación vive solo acá.
ModoVista = Literal["int", "ext", "int/ext", "ext/int"]
MomentoDia = Literal["dia", "noche", "amanecer", "atardecer", "anochecer"]
EstadoEscena = Literal["Pendiente", "En proceso", "Finalizada", "Eliminada"]


# ==========================================
# LÍMITES DE LA TABLA "escenas" (semana 6)
# ==========================================
# Hallazgos con PostgreSQL real: sin estos límites el valor pasaba el
# schema, la BD lo rechazaba al guardar y el API respondía 500:
# - numero_de_escena es varchar(45): 46 caracteres -> "value too long".
# - pagina, dia_dramatico, orden_rodaje y bloque_grabacion son integer de
#   4 bytes: 3.000.000.000 -> "integer out of range".
# - id_guion / id_rodaje / id_desglose son uuid: "abc" -> error de cast.
# Además se aceptaban un número de escena vacío y una página negativa.
NUMERO_ESCENA_MAX = 45
ENTERO_MIN = 0
ENTERO_MAX = 2_147_483_647  # máximo de un integer de PostgreSQL


def _uuid_opcional(valor):
    if valor is None:
        return valor
    try:
        UUID(str(valor))
    except ValueError:
        raise ValueError("debe ser un UUID válido")
    return valor


_IDS = ("id_guion", "id_rodaje", "id_desglose")
_ENTERO = dict(ge=ENTERO_MIN, le=ENTERO_MAX)


# ==========================================
# ESCENAS
# ==========================================
# id_escena no va en el schema de creación: lo genera el trigger de la
# base de datos (esc001, esc002, ...).
class SceneSchema(BaseModel):
    numero_de_escena: str = Field(min_length=1, max_length=NUMERO_ESCENA_MAX)
    encabezado: str = Field(min_length=1)
    descripcion: Optional[str] = None
    id_guion: Optional[str] = None
    modo_vista: Optional[ModoVista] = None
    momento_dia: Optional[MomentoDia] = None
    ciudad: Optional[str] = None
    pagina: Optional[int] = Field(default=None, **_ENTERO)
    fecha_de_grabacion: Optional[date] = None
    dia_dramatico: Optional[int] = Field(default=None, **_ENTERO)
    id_rodaje: Optional[str] = None
    id_desglose: Optional[str] = None
    estado: Optional[EstadoEscena] = "Pendiente"
    # Datos propios del Plan de Rodaje (no de la escena narrativa) — ver
    # scene_model.py y sql/007_plan_rodaje_datos_propios.sql.
    locacion_rodaje: Optional[str] = None
    tiempo_estimado: Optional[str] = None
    hora_inicio_rodaje: Optional[time] = None
    notas_rodaje: Optional[str] = None
    orden_rodaje: Optional[int] = Field(default=None, **_ENTERO)
    # Agrupación manual de escenas por "bloque de grabación" (1, 2, 3...)
    # — independiente de a qué día de rodaje esté asignada la escena, se
    # usa para filtrar en Plan de Rodaje y en Escenas (ver
    # sql/013_bloque_grabacion.sql).
    bloque_grabacion: Optional[int] = Field(default=None, **_ENTERO)
    # Comentarios libres de la escena, editables desde el panel
    # "Información de la Escena" — ver scene_model.py.
    comentarios: Optional[str] = None

    _ids_uuid = field_validator(*_IDS)(_uuid_opcional)


class SceneUpdateSchema(BaseModel):
    numero_de_escena: Optional[str] = Field(default=None, min_length=1, max_length=NUMERO_ESCENA_MAX)
    encabezado: Optional[str] = Field(default=None, min_length=1)
    descripcion: Optional[str] = None
    id_guion: Optional[str] = None
    modo_vista: Optional[ModoVista] = None
    momento_dia: Optional[MomentoDia] = None
    ciudad: Optional[str] = None
    pagina: Optional[int] = Field(default=None, **_ENTERO)
    fecha_de_grabacion: Optional[date] = None
    dia_dramatico: Optional[int] = Field(default=None, **_ENTERO)
    id_rodaje: Optional[str] = None
    id_desglose: Optional[str] = None
    estado: Optional[EstadoEscena] = None
    locacion_rodaje: Optional[str] = None
    tiempo_estimado: Optional[str] = None
    hora_inicio_rodaje: Optional[time] = None
    notas_rodaje: Optional[str] = None
    orden_rodaje: Optional[int] = Field(default=None, **_ENTERO)
    # Agrupación manual de escenas por "bloque de grabación" (1, 2, 3...)
    # — independiente de a qué día de rodaje esté asignada la escena, se
    # usa para filtrar en Plan de Rodaje y en Escenas (ver
    # sql/013_bloque_grabacion.sql).
    bloque_grabacion: Optional[int] = Field(default=None, **_ENTERO)
    comentarios: Optional[str] = None

    _ids_uuid = field_validator(*_IDS)(_uuid_opcional)
