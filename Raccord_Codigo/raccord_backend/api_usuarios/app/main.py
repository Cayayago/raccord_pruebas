import logging
import os

from dotenv import load_dotenv

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.routes.login_routes import router as login_router
from app.routes.register_routes import router as register_router
from app.routes.password_routes import router as password_router
from app.routes.user_routes import router as user_router
from app.routes.client_routes import router as client_router
from app.routes.project_routes import router as project_router
from app.routes.role_routes import router as role_router
from app.routes.department_routes import router as department_router
from app.routes.script_routes import router as script_router
from app.routes.scene_routes import router as scene_router
from app.routes.breakdown_routes import router as breakdown_router
from app.routes.shooting_day_routes import router as shooting_day_router
from app.routes.breakdown_sheet_routes import router as breakdown_sheet_router
from app.routes.character_routes import router as character_router
from app.routes.actor_routes import router as actor_router
from app.routes.scene_character_routes import router as scene_character_router
from app.routes.gallery_photo_routes import router as gallery_photo_router
from app.routes.crew_member_routes import router as crew_member_router
from app.routes.module_access_routes import router as module_access_router
from app.routes.contact_routes import router as contact_router
from app.routes.notification_routes import router as notification_router

from app.config.database import Base, engine
from app.utils.minio_client import ensure_buckets
from app.models.user_project_model import UserProject
from app.models.department_model import Department
from app.models.script_model import Script
from app.models.scene_model import Scene
from app.models.breakdown_model import DesgloseItem, DesgloseItemDetalle
from app.models.shooting_day_model import ShootingDay
from app.models.breakdown_sheet_model import BreakdownSheet
from app.models.character_model import Character
from app.models.actor_model import Actor
from app.models.scene_character_model import SceneCharacter
from app.models.gallery_photo_model import GalleryPhoto
from app.models.crew_member_model import CrewMember
from app.models.module_access_model import UserProjectModuleAccess
from app.models.revoked_token_model import RevokedToken
from app.models.notification_model import Notification, NotificationDepartamento, NotificationRead
from app.utils.response import api_response

load_dotenv()

logger = logging.getLogger("raccord")

# CREATE TABLES
Base.metadata.create_all(bind=engine)

# ASEGURAR BUCKETS DE MINIO (guiones, imagenes) - los crea si no existen
ensure_buckets()

# FASTAPI

app = FastAPI(
    title="API´S RACCORD",
    version="1.0"
)


# CORS - esto habilita a que react (o el nuevo frontend Flutter Web) puedan
# hacer peticiones a traves de las apis dispuesta en el backend.
#
# `flutter run -d chrome` (y `-d edge`) levanta el servidor de desarrollo
# en un puerto ALEATORIO cada vez (ej. http://localhost:49334), distinto de
# los puertos fijos 3000/5173 que usa React. Sin este origen en la lista, el
# navegador bloquea la petición por CORS *antes* de que llegue al backend, y
# el frontend lo interpreta como "no se pudo conectar con el servidor"
# aunque el backend esté funcionando bien (por eso funciona en Thunder
# Client/Postman, que no aplican CORS, pero falla solo en el navegador).
#
# `allow_origin_regex` cubre cualquier puerto de localhost/127.0.0.1 para
# desarrollo, sin tener que fijar `--web-port` cada vez que se corre Flutter.
#
# PRODUCCIÓN: cuando esto se despliegue en un dominio real, se agrega
# ese dominio en la variable de entorno ALLOWED_ORIGINS (separados por
# coma, ej. "https://app.raccord.com,https://raccord.com") en vez de
# tocar este archivo o usar "*" — con allow_credentials=True, FastAPI
# ni siquiera permite "*" como origen (lo bloquea en runtime), así que
# la whitelist explícita es la única opción correcta acá.
_extra_origins = [
    o.strip()
    for o in os.getenv("ALLOWED_ORIGINS", "").split(",")
    if o.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173", *_extra_origins],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ROUTES

# Auth (login, register, recuperación de contraseña) - entrada pública
app.include_router(login_router)
app.include_router(register_router)
app.include_router(password_router)

# Recursos protegidos por JWT
app.include_router(user_router)
app.include_router(client_router)
app.include_router(project_router)
app.include_router(role_router)
app.include_router(department_router)
app.include_router(script_router)
app.include_router(scene_router)
app.include_router(breakdown_router)
app.include_router(shooting_day_router)
app.include_router(breakdown_sheet_router)
app.include_router(character_router)
app.include_router(actor_router)
app.include_router(scene_character_router)
app.include_router(gallery_photo_router)
app.include_router(crew_member_router)
app.include_router(module_access_router)
app.include_router(notification_router)

# Landing / contacto - público
app.include_router(contact_router)


# ==========================================
# MANEJO GLOBAL DE ERRORES NO CONTROLADOS
# ==========================================
# Sin esto, cualquier excepción no capturada (ej. un dato corrupto en la
# BD, un error de hashing, etc.) devuelve un 500 vacío/sin CORS bien
# formado, y el frontend lo interpreta como "no se pudo conectar con el
# servidor" en vez de mostrar un mensaje claro. Aquí siempre respondemos
# JSON con el mismo formato api_response que usa el resto de la API.
@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Error no controlado en %s %s", request.method, request.url.path)

    return JSONResponse(
        status_code=500,
        content=api_response(
            False,
            "Ocurrió un error inesperado en el servidor",
            error="INTERNAL_SERVER_ERROR"
        )
    )


# HOME

@app.get("/")
def home():
    return {
        "success": True,
        "message": "API funcionando correctamente"
    }
