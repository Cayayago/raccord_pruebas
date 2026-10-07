from datetime import datetime, timedelta
import uuid
from jose import jwt, JWTError
import os
from dotenv import load_dotenv

# ==========================================
# CARGAR VARIABLES DE ENTORNO
# ==========================================
load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))


# ==========================================
# CREAR TOKEN JWT
# ==========================================
def create_access_token(data: dict):
    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    # jti = id único de ESTE token (no del usuario). Es lo que permite
    # invalidarlo puntualmente en el logout (ver app/utils/token_revocation.py)
    # sin tocar los demás tokens del mismo usuario que sigan vivos en
    # otro dispositivo/pestaña.
    to_encode.update({"exp": expire, "jti": str(uuid.uuid4())})

    token = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return token


# ==========================================
# DECODIFICAR / VALIDAR TOKEN
# ==========================================
def verify_token(token: str):
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        return payload

    except JWTError:
        return None
