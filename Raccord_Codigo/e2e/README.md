# Pruebas automatizadas (Playwright)

Cubren la API (permisos por rol, sesión, notificaciones, papelera, Crew List) y un humo de la UI web.

## Preparación (una vez)

```bash
cd e2e
pnpm install
pnpm exec playwright install chromium
python -m pip install -r ../raccord_backend/api_usuarios/requirements.txt
```

## Ejecutar (semana 7: contra la BD de pruebas)

La suite **no usa la BD de desarrollo ni usuarios cargados a mano**: Playwright arranca el backend por su cuenta contra `raccord_test` (puerto 5433) y el MinIO de pruebas (9100), y cada test crea su empresa, usuario y proyecto por API (`tests/support/datos.ts`).

Desde la raíz del repo:

```bash
docker compose stop backend                              # libera el puerto 8000 (el frontend de :8081 sigue)
docker compose -f docker-compose.test.yml up -d --wait   # BD y MinIO de pruebas
```

Y desde `e2e/`:

```bash
pnpm test                          # todo, en paralelo
pnpm test:api                      # solo API
pnpm test:ui                       # solo UI (necesita el frontend en :8081)
pnpm exec playwright test --repeat-each=5   # estabilidad
pnpm report                        # reporte HTML (trazas en los reintentos)
```

Si el puerto 8000 está ocupado, Playwright falla a propósito en lugar de reutilizar ese backend: así nunca se prueba por error contra desarrollo. Con `docker ps` verás quién lo ocupa: además de `backend`, puede ser `raccord-lb` (el balanceador de la prueba de escalado); se libera con `docker stop raccord-lb` y se vuelve a encender con `docker start raccord-lb`. En Windows, si una corrida anterior quedó colgada, puede quedar un `uvicorn` vivo: ciérralo antes de repetir.

Resultados: `playwright-report/` (HTML) y `results/junit.xml`.

> Los tests antiguos de `tests/api/` que leen `PROJECT_ID` y credenciales del `.env` (rol por rol) siguen existiendo; sin esas variables se saltan solos. Los nuevos no las necesitan.

## Notas
- Corren en paralelo: el backend de pruebas se arranca con `E2E_DISABLE_RATE_LIMIT=true`, que apaga solo los límites por IP (las reglas por cuenta del login siguen activas). Esa variable no existe en `.env` ni en `docker-compose.yml`: nunca se enciende en la app real.
- Un test marcado con `test.fail()` documenta un defecto conocido (hallazgo): pasa mientras el defecto exista y avisa cuando se corrija.
- Las pruebas de notificaciones crean notificaciones reales en el proyecto de prueba.
- `.env` está ignorado por git; nunca subas credenciales.
