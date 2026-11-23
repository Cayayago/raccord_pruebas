import { defineConfig } from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

const API = process.env.API_URL ?? 'http://localhost:8000';
const WEB = process.env.WEB_URL ?? 'http://localhost:8081';

// Semana 7 — la suite corre contra la BD de PRUEBAS (semana 6), nunca contra la
// de desarrollo. Playwright arranca el backend por su cuenta, apuntando a
// raccord_test (puerto 5433) y al MinIO de pruebas (9100). Antes de correr:
//
//   docker compose stop backend                          # libera el puerto 8000
//   docker compose -f docker-compose.test.yml up -d --wait
//
// (el frontend de "docker compose up" en :8081 llama a http://127.0.0.1:8000,
// o sea, al backend que levanta este archivo). Si el puerto 8000 está ocupado,
// Playwright falla en vez de reutilizar ese servidor: reuseExistingServer es
// false a propósito, para no probar sin querer contra el backend de desarrollo.
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: process.env.CI ? 1 : 0,
  // Sin "workers: 1": la suite corre en paralelo. Cada test crea su propia
  // empresa por API (tests/support/datos.ts), así que no comparten datos, y el
  // límite de intentos por IP se apaga SOLO en el backend de pruebas.
  reporter: [['list'], ['html', { open: 'never' }], ['junit', { outputFile: 'results/junit.xml' }]],
  use: { trace: 'on-first-retry' },
  projects: [
    { name: 'api', testMatch: /api\/.*\.spec\.ts/, use: { baseURL: API } },
    {
      name: 'ui',
      testMatch: /ui\/.*\.spec\.ts/,
      use: { baseURL: WEB, screenshot: 'only-on-failure', trace: 'on-first-retry' },
    },
  ],
  webServer: {
    command: 'python -m uvicorn app.main:app --port 8000',
    cwd: '../raccord_backend/api_usuarios',
    url: `${API}/docs`,
    reuseExistingServer: false,
    timeout: 60_000,
    env: {
      DB_HOST: 'localhost',
      DB_PORT: '5433',
      DB_USER: 'raccord_test',
      DB_PASSWORD: 'raccord_test',
      DB_NAME: 'raccord_test',
      MINIO_ENDPOINT: 'localhost:9100',
      MINIO_PUBLIC_ENDPOINT: 'localhost:9100',
      MINIO_ACCESS_KEY: 'raccord_test',
      MINIO_SECRET_KEY: 'raccord_test_secret',
      MINIO_SECURE: 'false',
      SECRET_KEY: process.env.SECRET_KEY ?? 'clave-solo-para-e2e-0123456789abcdef',
      ALGORITHM: 'HS256',
      ACCESS_TOKEN_EXPIRE_MINUTES: '60',
      // Solo existe aquí: ver app/utils/rate_limit.py (e2e_sin_limites).
      E2E_DISABLE_RATE_LIMIT: 'true',
    },
  },
});
