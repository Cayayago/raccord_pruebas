import io
import logging
from datetime import timedelta

from minio import Minio
from minio.error import S3Error

logger = logging.getLogger("raccord")

# ==========================================
# CLIENTE MINIO (almacenamiento de objetos S3-compatible)
# ==========================================
# Reemplaza el patrón anterior de guardar PDFs/fotos como BYTEA en
# Postgres. Un bucket por tipo de archivo:
#   - "guiones"  -> PDFs de guiones (antes guiones.archivo_contenido)
#   - "imagenes" -> fotos de continuidad (antes
#                   fotos_continuidad.archivo_contenido)
#   - "perfiles" -> fotos de perfil de usuario (users.foto_perfil_key)
#
# MINIO_ENDPOINT: host:puerto de la API S3 (dentro de docker compose es
# "minio:9000"; en desarrollo local sin Docker, "localhost:9000").
# MINIO_PUBLIC_ENDPOINT (opcional): si el backend habla con MinIO por un
# nombre interno de red que el navegador del usuario NO puede resolver
# (como "minio" dentro de docker compose), acá se indica el host/puerto
# público para que las URLs prefirmadas que ve el navegador sean
# accesibles. Si no se define, se usa MINIO_ENDPOINT para ambas cosas.
import os

from dotenv import load_dotenv

load_dotenv()

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9000")
MINIO_PUBLIC_ENDPOINT = os.getenv("MINIO_PUBLIC_ENDPOINT", MINIO_ENDPOINT)
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "raccord_admin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "raccord_minio_2026")
MINIO_SECURE = os.getenv("MINIO_SECURE", "false").lower() == "true"

BUCKET_GUIONES = "guiones"
BUCKET_IMAGENES = "imagenes"
BUCKET_PERFILES = "perfiles"

# Cuánto dura una URL prefirmada (para ver/descargar un PDF o una foto)
# antes de expirar. 1 hora es suficiente para abrir el archivo desde el
# frontend; si expira, el usuario simplemente vuelve a pedir el enlace
# (GET /scripts/{id}/archivo o GET /fotos/{id}/archivo de nuevo).
PRESIGNED_URL_EXPIRY = timedelta(hours=1)

# Cliente "interno" (el que usa el backend para subir/borrar archivos,
# habla por MINIO_ENDPOINT que solo necesita ser alcanzable desde dentro
# de la red de docker compose).
_client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE,
)

# Cliente "público" (solo se usa para FIRMAR urls, nunca hace la
# petición real) — apunta a MINIO_PUBLIC_ENDPOINT para que la URL
# resultante sea resoluble desde el navegador del usuario, no desde
# dentro de la red interna de docker compose.
if MINIO_PUBLIC_ENDPOINT != MINIO_ENDPOINT:
    _public_client = Minio(
        MINIO_PUBLIC_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=MINIO_SECURE,
    )
else:
    _public_client = _client


# ==========================================
# BOOTSTRAP: asegura que los buckets existan
# ==========================================
# Se llama una vez al arrancar la app (ver app/main.py), igual que
# Base.metadata.create_all para las tablas. Si el bucket ya existe no
# hace nada; si MinIO todavía no está listo (por ejemplo la primerísima
# vez que se levanta docker compose), solo se registra el error para no
# tumbar el arranque del backend completo por esto.
def ensure_buckets():
    for bucket in (BUCKET_GUIONES, BUCKET_IMAGENES, BUCKET_PERFILES):
        try:
            if not _client.bucket_exists(bucket):
                _client.make_bucket(bucket)
                logger.info("Bucket de MinIO creado: %s", bucket)
        except Exception as error:
            logger.error("No se pudo verificar/crear el bucket '%s' en MinIO: %s", bucket, error)


# ==========================================
# SUBIR UN ARCHIVO
# ==========================================
def upload_file(bucket: str, object_key: str, contenido: bytes, content_type: str):
    _client.put_object(
        bucket,
        object_key,
        data=io.BytesIO(contenido),
        length=len(contenido),
        content_type=content_type,
    )


# ==========================================
# BORRAR UN ARCHIVO (best-effort, no debe tumbar la operación de la BD)
# ==========================================
def delete_file(bucket: str, object_key: str | None):
    if not object_key:
        return

    try:
        _client.remove_object(bucket, object_key)
    except S3Error as error:
        logger.warning("No se pudo borrar '%s' del bucket '%s' en MinIO: %s", object_key, bucket, error)


# ==========================================
# DESCARGAR UN ARCHIVO (bytes crudos)
# ==========================================
# El endpoint (script_controller.get_script_archivo / gallery_photo_
# controller.get_photo_archivo) ya validó JWT + permisos antes de
# llamar acá, y devuelve estos bytes directo en la respuesta HTTP -
# mismo comportamiento que antes con BYTEA en Postgres, solo que ahora
# el binario vive en MinIO.
#
# Nota: se descarta a propósito la alternativa de redirigir al
# navegador a una URL prefirmada de MinIO (bucket-a-navegador directo,
# sin pasar por FastAPI) porque el navegador corre en otro origen
# (ej. localhost:8081) que MinIO (localhost:9000) y MinIO no manda
# cabeceras CORS por defecto - el fetch queda bloqueado en el
# navegador. Trayendo el archivo del lado del servidor (backend ->
# MinIO, sin navegador de por medio) se evita ese problema por
# completo.
def download_file(bucket: str, object_key: str) -> bytes:
    response = _client.get_object(bucket, object_key)
    try:
        return response.read()
    finally:
        response.close()
        response.release_conn()


# ==========================================
# URL PREFIRMADA (sin usar por ahora - ver nota en download_file)
# ==========================================
# Se deja disponible para el día que se quiera exponer un enlace
# directo a MinIO (ej. "copiar enlace"), configurando antes CORS en el
# bucket para el/los dominio(s) del frontend.
def get_presigned_url(bucket: str, object_key: str, filename: str, content_type: str | None = None):
    response_headers = {"response-content-disposition": f'inline; filename="{filename}"'}
    if content_type:
        response_headers["response-content-type"] = content_type

    return _public_client.presigned_get_object(
        bucket,
        object_key,
        expires=PRESIGNED_URL_EXPIRY,
        response_headers=response_headers,
    )
