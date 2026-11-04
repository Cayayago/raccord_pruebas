import uuid
from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from app.config.database import Base

# id_cliente es UUID (antes SERIAL) — ver sql/009_uuid_primary_keys.sql.
class Client(Base):
    __tablename__ = "clients"

    id_cliente = Column(
        UUID(as_uuid=True),
        primary_key=True,
        index=True,
        default=uuid.uuid4
    )

    document = Column(
        String(50),
        nullable=False
    )
    
    id_document = Column(
        Text,
        nullable=False
    )

    razon_social = Column(
        String(50),
        nullable=False
    )

    representante_legal = Column(
        String(100),
        nullable=False
    )

    email = Column(
        String(100),
        unique=True,
        nullable=False
    )

    address = Column(
        String(100)
    )

    # Nullable a propósito: el formulario de registro ya no pide
    # teléfono de la empresa (ver RegisterSchema.telephone, opcional).
    telephone = Column(
        String(15),
        nullable=True
    )

    number_cellphone = Column(
        String(20)
    )

