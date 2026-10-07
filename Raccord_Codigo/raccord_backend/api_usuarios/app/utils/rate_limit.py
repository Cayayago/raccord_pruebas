import time
from threading import Lock

from fastapi import HTTPException, Request, status

# ==========================================
# RATE LIMITING (protección de fuerza bruta)
# ==========================================
# Limitador simple en memoria, sin dependencias nuevas (mismo criterio
# que verified_devices/two_factor_codes/recovery_codes en
# login_controller.py y password_controller.py: son estructuras en
# memoria del proceso, suficientes para un solo backend). Cuenta
# intentos por (IP, clave lógica) en una ventana de tiempo fija; al
# superar el máximo, responde 429 hasta que la ventana expire.
#
# NOTA: si en el futuro el backend corre con más de un worker/proceso
# (ej. gunicorn con varios workers), este contador ya no sería
# compartido entre procesos y el límite real efectivo sería
# (máximo x cantidad de workers). Para ese caso habría que mover esto a
# Redis o similar. Por ahora el backend corre en un solo proceso
# (uvicorn, un worker), así que no aplica.
_attempts: dict[str, list[float]] = {}
_lock = Lock()


def _client_ip(request: Request) -> str:
    # Si en algún momento se pone un proxy/nginx delante del backend
    # (ya existe nginx para el frontend, pero no delante de la API),
    # habría que leer X-Forwarded-For acá. Por ahora el backend recibe
    # las conexiones directas.
    if request.client:
        return request.client.host
    return "unknown"


def rate_limit(key_prefix: str, max_attempts: int, window_seconds: int):
    """
    Dependency de FastAPI: limita a `max_attempts` llamadas por
    `window_seconds` segundos, contadas por IP de origen.

    Uso:
        @router.post("/login")
        def login(
            user: LoginSchema,
            db: Session = Depends(get_db),
            _rl = Depends(rate_limit("login", 8, 60)),
        ):
            ...
    """

    def dependency(request: Request):
        ip = _client_ip(request)
        key = f"{key_prefix}:{ip}"
        now = time.time()

        with _lock:
            intentos = _attempts.get(key, [])
            # Descarta intentos fuera de la ventana.
            intentos = [t for t in intentos if now - t < window_seconds]

            if len(intentos) >= max_attempts:
                _attempts[key] = intentos
                retry_after = int(window_seconds - (now - intentos[0])) + 1
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Demasiados intentos. Intenta de nuevo en unos minutos.",
                    headers={"Retry-After": str(retry_after)},
                )

            intentos.append(now)
            _attempts[key] = intentos

    return dependency
