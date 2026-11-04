from pydantic import BaseModel
from typing import Optional, Literal
from datetime import date, time

# Deben coincidir exactamente con los catálogos del frontend
# (kModosVista/kMomentosDia/kEstadosEscena en models/scene.dart) — ya no
# son ENUM reales de Postgres (ver comentario en scene_model.py), la
# columna es texto libre y esta validación vive solo acá.
ModoVista = Literal["int", "ext", "int/ext", "ext/int"]
MomentoDia = Literal["dia", "noche", "amanecer", "atardecer", "anochecer"]
EstadoEscena = Literal["Pendiente", "En proceso", "Finalizada", "Eliminada"]


# ==========================================
# ESCENAS
# ==========================================
# id_escena no va en el schema de creación: lo genera el trigger de la
# base de datos (esc001, esc002, ...).
class SceneSchema(BaseModel):
    numero_de_escena: str
    encabezado: str
    descripcion: Optional[str] = None
    id_guion: Optional[str] = None
    modo_vista: Optional[ModoVista] = None
    momento_dia: Optional[MomentoDia] = None
    ciudad: Optional[str] = None
    pagina: Optional[int] = None
    fecha_de_grabacion: Optional[date] = None
    dia_dramatico: Optional[int] = None
    id_rodaje: Optional[str] = None
    id_desglose: Optional[str] = None
    estado: Optional[EstadoEscena] = "Pendiente"
    # Datos propios del Plan de Rodaje (no de la escena narrativa) — ver
    # scene_model.py y sql/007_plan_rodaje_datos_propios.sql.
    locacion_rodaje: Optional[str] = None
    tiempo_estimado: Optional[str] = None
    hora_inicio_rodaje: Optional[time] = None
    notas_rodaje: Optional[str] = None
    orden_rodaje: Optional[int] = None
    # Agrupación manual de escenas por "bloque de grabación" (1, 2, 3...)
    # — independiente de a qué día de rodaje esté asignada la escena, se
    # usa para filtrar en Plan de Rodaje y en Escenas (ver
    # sql/013_bloque_grabacion.sql).
    bloque_grabacion: Optional[int] = None
    # Comentarios libres de la escena, editables desde el panel
    # "Información de la Escena" — ver scene_model.py.
    comentarios: Optional[str] = None


class SceneUpdateSchema(BaseModel):
    numero_de_escena: Optional[str] = None
    encabezado: Optional[str] = None
    descripcion: Optional[str] = None
    id_guion: Optional[str] = None
    modo_vista: Optional[ModoVista] = None
    momento_dia: Optional[MomentoDia] = None
    ciudad: Optional[str] = None
    pagina: Optional[int] = None
    fecha_de_grabacion: Optional[date] = None
    dia_dramatico: Optional[int] = None
    id_rodaje: Optional[str] = None
    id_desglose: Optional[str] = None
    estado: Optional[EstadoEscena] = None
    locacion_rodaje: Optional[str] = None
    tiempo_estimado: Optional[str] = None
    hora_inicio_rodaje: Optional[time] = None
    notas_rodaje: Optional[str] = None
    orden_rodaje: Optional[int] = None
    # Agrupación manual de escenas por "bloque de grabación" (1, 2, 3...)
    # — independiente de a qué día de rodaje esté asignada la escena, se
    # usa para filtrar en Plan de Rodaje y en Escenas (ver
    # sql/013_bloque_grabacion.sql).
    bloque_grabacion: Optional[int] = None
    comentarios: Optional[str] = None
