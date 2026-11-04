# Seguridad operativa de Raccord

Guía corta de lo que hay que hacer (una vez o periódicamente) para cumplir
RNF-004, RNF-013, RNF-014 y RNF-016.

## RNF-013 — Cifrado de datos en reposo

**Qué está activo**
- Archivos (guiones, fotos, perfiles): MinIO cifra con AES-256 todo objeto
  nuevo (SSE-S3) usando la clave `MINIO_KMS_SECRET_KEY`. El backend lo
  activa al arrancar (`MINIO_ENCRYPT=true`) y hace una subida de prueba; si
  falla, lo desactiva solo y deja un aviso en el log (la app no se rompe).
- Contraseñas: hash bcrypt de 12 rondas.

**Cifrar lo que ya estaba subido (una sola vez)**

    docker compose up -d --build
    docker compose exec backend python -m app.utils.encrypt_existing_objects

**Verificar:** en el log del backend debe aparecer
`Cifrado AES-256 en reposo activo en el bucket ...`. En la consola de MinIO
(puerto 9001) el objeto muestra "Server-side encryption: SSE-S3".

**La clave**
- En desarrollo se usa una clave fija del `docker-compose.yml`.
- En producción generar una propia (ver `.env.prod.example`) y guardar una
  copia fuera del servidor. Sin la clave los archivos NO se pueden recuperar.

**Rotación cada 90 días.** MinIO con clave estática admite una sola clave a
la vez, así que rotar es migrar: levantar una segunda instancia de MinIO con
la clave nueva y copiar todo (`mc mirror vieja/ nueva/`); después apuntar el
backend a la nueva y retirar la anterior. Para rotación automática sin
migraciones conviene usar MinIO KES (gestor de claves) en producción.

**Pendiente de infraestructura (no es código):** cifrado del disco/volumen
de PostgreSQL (opción de cifrado de almacenamiento del proveedor de nube o
LUKS en el servidor) y copias de seguridad cifradas.

## RNF-014 — TLS 1.3

Archivos: `docker-compose.prod.yml`, `Caddyfile`, `.env.prod.example`.

    cp .env.prod.example .env      # completar dominios y claves
    docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

Caddy emite y renueva solo los certificados, redirige HTTP a HTTPS, fuerza
TLS 1.3 y añade HSTS. Verificación: https://www.ssllabs.com/ssltest/ (debe
dar A o A+) y probar `http://app.tu-dominio.com` (debe redirigir a https).

## RNF-004 — Bloqueo por intentos fallidos

- 5 fallos por cuenta en 15 min: bloqueo de 15 min.
- 20 fallos desde una IP en 1 h: bloqueo de la IP por 1 h.
- 10 fallos por cuenta en 24 h: bloqueo hasta que un administrador llame
  `POST /users/{id}/desbloquear`.
- Detrás del proxy de producción hay que tener `TRUST_PROXY_HEADERS=true`
  (ya lo pone `docker-compose.prod.yml`) para que se cuente la IP real.

## RNF-016 — Sesiones

JWT de 60 min (`ACCESS_TOKEN_EXPIRE_MINUTES`), revocado al cerrar sesión,
cierre por inactividad a los 15 min con aviso a los 60 s.
