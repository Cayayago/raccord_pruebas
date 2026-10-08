# Pruebas automatizadas (Playwright)

Cubren la API (permisos por rol, sesión, notificaciones, papelera, Crew List) y un humo de la UI web.

## Preparación (una vez)

```bash
cd e2e
pnpm install
pnpm exec playwright install chromium
cp .env.example .env     # y completa PROJECT_ID + un usuario por rol
```

Usa un **proyecto de prueba** con un usuario por rol (Admin, Director, Jefe, Onset, Usuario). Las pruebas de un rol sin credenciales se saltan solas.

## Ejecutar

Con `docker compose up -d` corriendo:

```bash
pnpm test              # todo
pnpm test:api      # solo API
pnpm test:ui       # solo UI
pnpm report        # reporte HTML
```

La primera vez, las pruebas de UI con capturas fallan por no existir referencia: corre `pnpm exec playwright test --project=ui --update-snapshots` una vez para crearlas.

Resultados: `playwright-report/` (HTML) y `results/junit.xml`.

## Notas
- Corren en serie: el backend limita el login a 8 intentos/minuto por IP.
- Las pruebas de notificaciones crean notificaciones reales en el proyecto de prueba.
- `.env` está ignorado por git; nunca subas credenciales.
