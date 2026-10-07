from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
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
