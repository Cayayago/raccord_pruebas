from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from jose import jwt, JWTError

from app.config.database import get_db
from app.utils.security import SECRET_KEY, ALGORITHM
from app.utils.permissions import has_permission
from app.utils.token_revocation import is_token_revoked

# ==========================================
# ESQUEMA DE AUTENTICACIÓN (Bearer Token)
# ==========================================
security = HTTPBearer()


# ==========================================
# OBTENER USUARIO DESDE TOKEN
# ==========================================
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):

    token = credentials.credentials  # <-- solo el token sin "Bearer"

    try:
        # Decodificar token
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Token con firma y "exp" válidos, pero cerrado explícitamente por
    # el propio usuario (POST /users/logout) — ver
    # app/utils/token_revocation.py. Sin este chequeo, "Salir" solo
    # borraba el token del lado del cliente y el mismo token seguía
    # sirviendo contra la API hasta su expiración natural.
    if is_token_revoked(db, payload.get("jti")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión cerrada. Vuelve a iniciar sesión.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    return payload  # devuelve datos del token (id_user, mail, id_rol, etc.)


# ==========================================
# RESTRINGIR ACCESO POR ROL (uso opcional)
# ==========================================
# Ejemplo de uso en una ruta:
#
#   @router.delete("/roles/{id}")
#   def destroy_role(
#       id: int,
#       db: Session = Depends(get_db),
#       user = Depends(require_roles(1001))  # solo id_rol == 1001 puede entrar
#   ):
#       return delete_role(id, db)
#
def require_roles(*allowed_roles: int):
    def wrapper(current_user: dict = Depends(get_current_user)):
        if current_user.get("id_rol") not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta acción"
            )
        return current_user

    return wrapper


# ==========================================
# RESTRINGIR ACCESO POR PERMISO (matriz de roles)
# ==========================================
# Usa la matriz definida en app/utils/permissions.py, así que las reglas
# de negocio (qué puede hacer cada rol) viven en un solo lugar.
#
# Ejemplo de uso:
#
#   @router.post("/projects")
#   def store_project(
#       project: ProjectSchema,
#       db: Session = Depends(get_db),
#       user = Depends(require_permission("create_project"))
#   ):
#       return create_project(project, db)
#
def require_permission(permission: str):
    def wrapper(current_user: dict = Depends(get_current_user)):
        if not has_permission(current_user.get("id_rol"), permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta acción"
            )
        return current_user

    return wrapper
