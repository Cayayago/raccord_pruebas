import { defineConfig } from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

const API = process.env.API_URL ?? 'http://localhost:8000';
const WEB = process.env.WEB_URL ?? 'http://localhost:8081';

// Backend, BD y frontend se levantan antes (desde Raccord_Codigo):
//   docker compose up -d
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: process.env.CI ? 1 : 0,
  // El backend limita intentos de login (8/min por IP): se corre en serie.
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }], ['junit', { outputFile: 'results/junit.xml' }]],
  projects: [
    { name: 'api', testMatch: /api\/.*\.spec\.ts/, use: { baseURL: API } },
    {
      name: 'ui',
      testMatch: /ui\/.*\.spec\.ts/,
      use: { baseURL: WEB, screenshot: 'only-on-failure', trace: 'on-first-retry' },
    },
  ],
  // El stack (BD + backend + frontend) lo levantas tú antes con "docker compose up -d".
});
