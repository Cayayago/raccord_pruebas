import uuid
from sqlalchemy import Column, String, Text, Date, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# ==========================================
# ACTOR MODEL (tabla "actors")
# ==========================================
# id_actor es UUID, generado en Python (uuid.uuid4) — ver
# sql/009_uuid_primary_keys.sql. Antes lo armaba un trigger de Postgres
# ('act1', 'act2'...) con una secuencia central, propensa a colisionar
# si dos clientes crean actores sin conexión al mismo tiempo.
#
# "genero" es ENUM en Postgres (generosex: masculino/fenemino/otro —
# el typo "fenemino" es el valor real que existe en la BD, no un error
# de este archivo), mapeado como texto plano igual que el resto de
# enums del proyecto (la validación estricta va en el schema Pydantic).
#
# id_personaje es la llave foránea hacia personajes.id_personaje (con
# ON DELETE CASCADE en la BD): así es como un actor queda "casteado"
# en un personaje. Es nullable porque un actor puede existir en el
# catálogo sin estar asignado todavía a ningún personaje.
class Actor(Base):
    __tablename__ = "actors"

    id_actor = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    # Solo nombre/apellido son obligatorios de verdad (ver
    # sql/020_actor_campos_opcionales.sql) — pedido explícito del
    # usuario (2026-09-03): poder crear el actor con lo mínimo y subir
    # sus 2 fotos de inmediato, completando el resto de la ficha técnica
    # (medidas, físico, nacionalidad, fecha de nacimiento) después, en
    # vez de tener que diligenciarla entera antes de poder asociarle una
    # foto (las fotos necesitan un id_actor real, que solo existe una
    # vez creado el registro).
    nombre = Column(String(45), nullable=False)
    apellido = Column(String(45), nullable=False)
    genero = Column(String(20), nullable=True)
    fecha_de_nacimiento = Column(Date, nullable=True)

    talla_zapatos = Column(String(10), nullable=True)
    ancho_espalda = Column(String(30), nullable=True)
    pecho = Column(String(30), nullable=True)
    cintura = Column(String(30), nullable=True)
    cadera = Column(String(30), nullable=True)
    largo_manga = Column(String(30), nullable=True)
    largo_pierna = Column(String(30), nullable=True)
    talla_anillo = Column(Text, nullable=True)
    contorno_cabeza = Column(String(30), nullable=True)
    contorno_cuello = Column(String(30), nullable=True)

    color_cabello = Column(String(45), nullable=True)
    textura_cabello = Column(String(45), nullable=True)
    tipo_piel = Column(String(45), nullable=True)
    color_ojos = Column(String(45), nullable=True)
    # Tono de piel (color): distinto de "tipo_piel" (grasa/seca/mixta),
    # pedido explícito del usuario (2026-09-03) para caracterización de
    # casting. Opcional para no romper fichas ya guardadas sin este dato.
    # Ver sql/019_actor_tono_piel.sql.
    tono_piel = Column(String(30), nullable=True)

    alergias = Column(Text, nullable=True)
    habilidades_especiales = Column(Text, nullable=True)
    restricciones = Column(Text, nullable=True)
    comentarios_adicionales = Column(Text, nullable=True)

    nacionalidad = Column(String(50), nullable=True)
    doble_riesgo = Column(Boolean, nullable=True)

    # index=True: GET /actors/character/{id_personaje} filtra por esta
    # columna (ver sql/022_indices_faltantes.sql).
    id_personaje = Column(  # llave foránea -> personajes.id_personaje
        UUID(as_uuid=True),
        ForeignKey("personajes.id_personaje", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    # Fotos del actor (bucket MinIO "imagenes", mismo patrón que
    # users.foto_perfil_key) — pedido explícito del usuario (2026-09-02):
    # "actor en personaje" (caracterizado) y "actor normal" (su propia
    # imagen), como el inicio de la ficha técnica. Solo se guarda la
    # key del objeto, nunca el binario en Postgres. Ver
    # sql/017_actors_fotos.sql.
    foto_personaje_key = Column(Text, nullable=True)
    foto_normal_key = Column(Text, nullable=True)

    # ==========================================
    # Contacto de producción (ver Cast List / sql/018_actor_contacto_casting.sql)
    # ==========================================
    # Datos de contacto del actor, no de su ficha física — pedido
    # explícito del usuario (2026-09-02) al comparar contra un Cast List
    # real (documento de producción con columnas CÉDULA/DIRECCIÓN/
    # TELÉFONO/CORREO).
    cedula = Column(String(50), nullable=True)
    direccion = Column(Text, nullable=True)
    telefono = Column(String(30), nullable=True)
    correo = Column(String(120), nullable=True)

    # ==========================================
    # Seguimiento de casting (mismo Cast List)
    # ==========================================
    # "status_confirmacion" y "categoria_cast" son texto libre validado
    # solo en el schema (mismo criterio que estado/momento_dia de
    # Scene) para no depender de un ENUM real de Postgres.
    status_confirmacion = Column(String(20), nullable=True)
    llamados = Column(Text, nullable=True)  # texto libre: "19", "3", etc. — el PDF trae también celdas vacías
    fechas_tentativas = Column(Text, nullable=True)
    guion_enviado = Column(Boolean, nullable=True)
    ensayos = Column(Text, nullable=True)
    categoria_cast = Column(String(30), nullable=True)

    # Aislamiento por proyecto (ver sql/015_project_scoping.sql). No basta
    # con resolverlo vía `id_personaje` porque ese campo es opcional (un
    # actor puede existir sin personaje asignado todavía) — sin su propio
    # id_project, un actor "suelto" no tendría forma de saber a qué
    # proyecto pertenece. Nullable=True solo para la migración de filas
    # existentes; toda fila nueva lo exige (ActorSchema).
    id_project = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id_project", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
