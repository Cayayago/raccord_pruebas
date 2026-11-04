import uuid
from sqlalchemy import Column, String, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# CREW MEMBER MODEL (tabla "personal_produccion")
# ==========================================
# "Crew List" del menú lateral (ver app_scaffold.dart) — pedido
# explícito del usuario: un directorio de TODAS las personas que
# trabajan en el proyecto (director, jefes de departamento, técnicos,
# etc.), tengan o no cuenta de acceso a la plataforma. Es independiente
# de "usuarios" (cuentas de acceso) y de "personajes"/"actores" (cast
# de ficción) — un mismo humano puede aparecer en más de una de esas
# listas sin que estén vinculadas entre sí, igual que el resto de
# catálogos del proyecto (personajes, actores).
#
# id_crew es UUID generado en Python (uuid.uuid4), mismo criterio que
# el resto de tablas desde la migración a UUID (ver
# sql/009_uuid_primary_keys.sql).
class CrewMember(Base):
    __tablename__ = "personal_produccion"

    id_crew = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    # El comentario de arriba ya decía "TODAS las personas que trabajan
    # EN EL PROYECTO" — la intención siempre fue que esto viviera por
    # proyecto, pero la tabla se creó sin esa columna (bug real: sin
    # esto, Crew List mezclaba el personal de TODOS los proyectos de
    # TODOS los clientes). Nullable=True solo para la migración de filas
    # existentes (ver scripts/backfill_project_scoping.py); toda fila
    # nueva lo exige (CrewMemberSchema).
    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    nombre = Column(
        String(120),
        nullable=False
    )

    # Cargo/oficio de producción (ej. "Director", "Sonidista",
    # "Gaffer", "Continuista") — texto libre a propósito: es un oficio,
    # no el rol de permisos de la plataforma (ver roles.id_rol), y la
    # lista de oficios de un rodaje no es un catálogo cerrado.
    cargo = Column(
        String(120),
        nullable=False
    )

    # index=True: Crew List se filtra por departamento (pedido explícito
    # del usuario, ver sql/022_indices_faltantes.sql).
    id_departamento = Column(  # llave foránea -> departamentos.id_departamento (opcional)
        UUID(as_uuid=True),
        ForeignKey("departamentos.id_departamento", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    celular = Column(
        String(30)
    )

    correo = Column(
        String(120)
    )

    notas = Column(
        Text
    )
