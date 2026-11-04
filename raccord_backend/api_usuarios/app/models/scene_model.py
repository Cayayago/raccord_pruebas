import uuid
from sqlalchemy import Column, Integer, String, Text, Date, Time, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# SCENE MODEL (tabla "escenas")
# ==========================================
# id_escena es UUID, generado en Python (uuid.uuid4) — ver
# sql/009_uuid_primary_keys.sql. Antes lo armaba un trigger
# (gen_id_escena, 'esc001', 'esc002'...) con una secuencia central, que
# podía colisionar si dos clientes creaban escenas sin conexión.
#
# "modo_vista" (vistalugar: int/ext/int-ext/ext-int) y "momento_dia"
# (momentodia: dia/noche/amanecer/atardecer/...) son ENUM en Postgres,
# mapeados como texto plano igual que el resto de enums del proyecto.
class Scene(Base):
    __tablename__ = "escenas"

    id_escena = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    numero_de_escena = Column(
        String(45),
        nullable=False
    )

    encabezado = Column(
        Text,
        nullable=False
    )

    descripcion = Column(
        Text
    )

    # index=True: GET /scenes/script/{id_guion} filtra por esta columna
    # (ver sql/022_indices_faltantes.sql).
    id_guion = Column(  # llave foránea -> guiones.id_guion
        UUID(as_uuid=True),
        ForeignKey("guiones.id_guion", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    modo_vista = Column(
        String(20)
    )

    momento_dia = Column(
        String(20)
    )

    ciudad = Column(
        Text
    )

    pagina = Column(
        Integer
    )

    fecha_de_grabacion = Column(
        Date
    )

    dia_dramatico = Column(
        Integer
    )

    # index=True: GET /scenes/rodaje/{id_rodaje} filtra por esta columna
    # (ver sql/022_indices_faltantes.sql).
    id_rodaje = Column(  # llave foránea -> plan_rodaje.id_rodaje
        UUID(as_uuid=True),
        ForeignKey("plan_rodaje.id_rodaje", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    # index=True: GET /scenes/desglose/{id_desglose} filtra por esta
    # columna (ver sql/022_indices_faltantes.sql).
    id_desglose = Column(  # llave foránea -> desgloses.id_desglose
        UUID(as_uuid=True),
        ForeignKey("desgloses.id_desglose", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    # Estado de seguimiento de la escena (Pendiente / En proceso /
    # Finalizada) — ver sql/004_escenas_estado_y_fotos.sql. No es un
    # ENUM de Postgres (para no depender de una migración de tipo),
    # solo texto validado del lado de la API (ver EstadoEscena en
    # scene_schema.py).
    estado = Column(
        String(20),
        nullable=False,
        server_default="Pendiente"
    )

    # ==========================================
    # Datos PROPIOS del Plan de Rodaje (ver sql/007_plan_rodaje_datos_propios.sql)
    # ==========================================
    # Distintos de los datos narrativos de la escena (encabezado,
    # descripción, INT/EXT, momento, día dramático...): estos campos
    # solo tienen sentido mientras la escena está asignada a un día de
    # rodaje (id_rodaje) y se editan desde la pantalla de Plan de
    # Rodaje, no desde el editor general de Escenas.
    locacion_rodaje = Column(  # dirección/locación física de grabación (distinta de "ciudad")
        Text
    )

    tiempo_estimado = Column(  # texto libre ("45 min", "1h 30min"...) — igual que en el referente
        Text
    )

    hora_inicio_rodaje = Column(  # hora de esta escena puntual dentro del día (distinta de plan_rodaje.hora_inicio, que es la hora de llamado general)
        Time
    )

    notas_rodaje = Column(  # notas específicas de rodaje para esta escena (distintas de plan_rodaje.notas, que es del día completo)
        Text
    )

    orden_rodaje = Column(  # posición manual (drag-and-drop) dentro del stripboard de su día
        Integer
    )

    bloque_grabacion = Column(  # agrupación manual (1, 2, 3...) para filtrar en Plan de Rodaje/Escenas — ver sql/013_bloque_grabacion.sql
        Integer
    )

    # Campo libre de comentarios de la escena (distinto de "descripcion",
    # que es la sinopsis narrativa fijada al crear la escena, y de
    # "notas_rodaje", específicas del día de rodaje) — editable desde el
    # panel "Información de la Escena" en Continuidad Visual. Pedido
    # explícito del usuario (2026-09-02). Ver sql/016_scene_comentarios.sql.
    comentarios = Column(
        Text
    )
