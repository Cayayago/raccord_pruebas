"""
RNF-013 — cifra los archivos que YA estaban en MinIO antes de activar el
cifrado por defecto (los nuevos se cifran solos al subirlos).

Uso (una sola vez, con el stack levantado):

    docker compose exec backend python -m app.utils.encrypt_existing_objects

Qué hace: por cada objeto de los buckets guiones/imagenes/perfiles que no
tenga cifrado del lado del servidor, lo lee y lo vuelve a escribir con la
misma ruta y tipo; el bucket (con cifrado por defecto) lo guarda cifrado.
Es seguro repetirlo: lo que ya está cifrado se salta.
"""
import io

from app.utils.minio_client import (
    _client,
    BUCKET_GUIONES,
    BUCKET_IMAGENES,
    BUCKET_PERFILES,
)

SSE_HEADER = "x-amz-server-side-encryption"


def _ya_cifrado(bucket: str, key: str) -> bool:
    info = _client.stat_object(bucket, key)
    meta = {str(k).lower(): v for k, v in (info.metadata or {}).items()}
    return SSE_HEADER in meta


def main():
    total = cifrados = saltados = fallidos = 0
    for bucket in (BUCKET_GUIONES, BUCKET_IMAGENES, BUCKET_PERFILES):
        if not _client.bucket_exists(bucket):
            continue
        for obj in _client.list_objects(bucket, recursive=True):
            total += 1
            key = obj.object_name
            try:
                if _ya_cifrado(bucket, key):
                    saltados += 1
                    continue
                resp = _client.get_object(bucket, key)
                try:
                    data = resp.read()
                    ctype = resp.headers.get("Content-Type", "application/octet-stream")
                finally:
                    resp.close()
                    resp.release_conn()
                _client.put_object(bucket, key, io.BytesIO(data), len(data), content_type=ctype)
                if _ya_cifrado(bucket, key):
                    cifrados += 1
                else:
                    fallidos += 1
                    print(f"[AVISO] {bucket}/{key} se reescribió pero NO quedó cifrado "
                          f"(¿bucket sin cifrado por defecto?)")
            except Exception as error:
                fallidos += 1
                print(f"[ERROR] {bucket}/{key}: {error}")

    print(f"Objetos: {total} | cifrados ahora: {cifrados} | ya cifrados: {saltados} | fallidos: {fallidos}")


if __name__ == "__main__":
    main()
