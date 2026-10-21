from passlib.context import CryptContext

# RNF-013: bcrypt con 12 rondas fijadas explícitamente (antes dependía
# del valor por defecto de la librería, que también es 12). Los hashes
# ya guardados siguen verificando igual: la cantidad de rondas viaja
# dentro de cada hash.
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12,
)


# ==========================================
# HASH PASSWORD
# ==========================================
def hash_password(password: str):
    # bcrypt solo acepta 72 bytes
    if len(password) > 72:
        password = password[:72]

    return pwd_context.hash(password)


# ==========================================
# VERIFY PASSWORD
# ==========================================
def verify_password(plain_password, hashed_password):
    if len(plain_password) > 72:
        plain_password = plain_password[:72]

    return pwd_context.verify(plain_password, hashed_password)
