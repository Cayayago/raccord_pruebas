import uuid
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.config.database import Base

# USER MODEL
#
# id_user es UUID (antes SERIAL) — ver sql/009_uuid_primary_keys.sql.
# id_rol se deja como entero a propósito: el sistema de permisos
# (app/utils/permissions.py) está hardcodeado con los IDs fijos
# 1001-1005 de la tabla "roles", que NO se convirtió a UUID.
class User(Base):
    __tablename__ = "users"

    id_user = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    nombre = Column(
        String(255),
        nullable=False
    )
    
    apellido = Column(
        String(255),
        nullable=False
    )
    identificacion = Column(
        String(50),
        nullable=False
    )

    id_identificacion = Column(
        String(50),
        unique=True,
        nullable=False
    )

    mail = Column(
        String(150),
        unique=True,
        nullable=False
    )

    msisdn = Column(
        String(20),
        nullable=False
    )

    direccion = Column(
        String(150),
    )

    fecha_de_nacimiento = Column(
        DateTime,
        nullable=False
    )

    estado = Column(
        String(20),
        nullable=False
    )
    
    fecha_de_creacion = Column(
        DateTime,
        server_default=func.now()
    )
    
    ultimo_acceso = Column(
        DateTime,
        server_default=func.now()
    )

    contrasena = Column(
        String(255),
        nullable=False
    )

    # Nullable a propósito: al registrarse (POST /register), el usuario
    # se crea sin departamento ni proyecto asignado todavía (ver
    # register_controller.register), igual que en el esquema original.
    #
    # ondelete="SET NULL" (antes CASCADE, ver sql/023_fk_ondelete_seguros.sql):
    # borrar un departamento NO debe borrar a las personas de esa área
    # — la app ya bloquea ese borrado si hay usuarios asignados
    # (department_controller.delete_department), CASCADE era solo una
    # trampa por si se borraba el departamento directo en SQL.
    # index=True: Jefe de Departamento filtra/gestiona por su propia
    # área en varios endpoints (ver sql/022_indices_faltantes.sql).
    id_departamento = Column(  # llave foránea -> departamentos.id_departamento
        UUID(as_uuid=True),
        ForeignKey("departamentos.id_departamento", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # A qué empresa/cliente pertenece este usuario — se setea al crearlo
    # (registro propio o invitación), NO se deriva de sus proyectos. Ver
    # sql/011_users_id_client.sql para el porqué: antes se calculaba vía
    # user_projects -> projects.id_client, pero eso falla para un
    # usuario recién registrado que todavía no tiene ningún proyecto.
    # index=True: el aislamiento multi-tenant por cliente se consulta en
    # casi todos los endpoints de /users y /clients (ver
    # sql/022_indices_faltantes.sql).
    id_client = Column(
        UUID(as_uuid=True),
        ForeignKey("clients.id_cliente", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    id_rol = Column(
        Integer,
        nullable=False
    )

    # Ruta del objeto en el bucket "perfiles" de MinIO (ver
    # app/utils/minio_client.py) — igual que con guiones/fotos de
    # continuidad, el binario NO se guarda en Postgres, solo la ruta.
    # Se sube con POST /users/me/foto y se sirve con
    # GET /users/{id}/foto.
    foto_perfil_key = Column(
        Text,
        nullable=True
    )
