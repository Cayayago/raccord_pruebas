import { test, expect, type Page, type Route } from '@playwright/test';
import { abrirApp } from './flutter';

// Flutter expone cada campo del login como un textbox llamado como su hint
// (la etiqueta "E-mail" queda como texto suelto, fuera del grupo).
const correo = (page: Page) => page.getByRole('textbox', { name: 'Ingresa tu correo' });
const clave = (page: Page) => page.getByRole('textbox', { name: 'Ingresa tu contraseña' });

// Semana 5 — E2E con dobles (Javier, capa E2E).
//
// Estados que el backend real no puede provocar a voluntad: API caído, un 500
// sin JSON, un 422 de validación y "no tienes proyectos". Se simulan con
// page.route, que intercepta la petición del navegador ANTES de que salga:
// la app Flutter corre de verdad, lo único falso es lo que responde el API.
//
// Tipos de doble usados:
// - Stub: responde una respuesta enlatada (fulfill) o una falla (abort).
// - Spy: el contador de peticiones (`llamadas`) registra qué se llamó y qué no.
//
// Las respuestas llevan CORS porque la web (8081) y el API (8000) son
// orígenes distintos y el navegador revisa la respuesta aunque sea simulada.

const CORS = { 'access-control-allow-origin': '*' };

const respuestaJson = (route: Route, cuerpo: unknown, status = 200) =>
  route.fulfill({ status, contentType: 'application/json', headers: CORS, body: JSON.stringify(cuerpo) });

/** Contador de peticiones a una ruta del API (spy). */
function espiar(page: Page, patron: string, respuesta: (route: Route) => Promise<void>) {
  const espia = { llamadas: 0, urls: [] as string[] };
  void page.route(patron, async (route) => {
    // El preflight de CORS (OPTIONS) no cuenta como llamada de la app.
    if (route.request().method() === 'OPTIONS') {
      return route.fulfill({
        status: 204,
        headers: { ...CORS, 'access-control-allow-headers': '*', 'access-control-allow-methods': '*' },
      });
    }
    espia.llamadas += 1;
    espia.urls.push(new URL(route.request().url()).pathname);
    return respuesta(route);
  });
  return espia;
}

async function iniciarSesion(page: Page) {
  await abrirApp(page, '/');
  await expect(correo(page)).toBeVisible();
  // `fill` no es confiable con los campos de Flutter (a veces no llega al
  // controlador): se enfoca cada campo y se escribe con el teclado.
  await correo(page).click();
  await page.keyboard.type('persona@raccord.test');
  await clave(page).click();
  await page.keyboard.type('Clave123!');
  await page.getByRole('button', { name: 'Ingresar' }).click();
}

test.describe('UI — estados difíciles con page.route', () => {
  test('API caído: avisa que no hay conexión, no intenta el login y no entra', async ({ page }) => {
    // Arrange: stub de falla de red en el primer paso del login
    const check = espiar(page, '**/users/2fa/check', (route) => route.abort('connectionrefused'));
    const login = espiar(page, '**/users/login', (route) => respuestaJson(route, { success: true }));
    // Act
    await iniciarSesion(page);
    // Assert (comportamiento): se intentó una vez el chequeo y NUNCA el login
    await expect(page.getByText(/No fue posible conectar con el servidor/).first()).toBeVisible({ timeout: 10_000 });
    expect(check.llamadas).toBe(1);
    expect(login.llamadas).toBe(0);
    // Assert (estado): sigue en el login
    await expect(page).not.toHaveURL(/#\/proyectos/);
    await expect(page.getByRole('button', { name: 'Ingresar' })).toBeVisible();
  });

  test('500 sin JSON: muestra el código HTTP en vez de dejar la pantalla colgada', async ({ page }) => {
    // Arrange: stub con un 500 que no es JSON (como el de un proxy caído)
    await page.route('**/users/2fa/check', (route) =>
      route.fulfill({ status: 500, contentType: 'text/html', headers: CORS, body: '<h1>Internal Server Error</h1>' }),
    );
    // Act
    await iniciarSesion(page);
    // Assert
    await expect(page.getByText('Error de conexión con el servidor (500)').first()).toBeVisible({ timeout: 10_000 });
    await expect(page).not.toHaveURL(/#\/proyectos/);
    await expect(page.getByRole('button', { name: 'Ingresar' })).toBeVisible();
  });

  test('422 de validación: muestra el mensaje del campo en vez del JSON crudo', async ({ page }) => {
    // Arrange: stub con la forma que usa Pydantic en un 422
    await page.route('**/users/2fa/check', (route) =>
      respuestaJson(route, { detail: [{ loc: ['body', 'mail'], msg: 'El correo no es válido', type: 'value_error' }] }, 422),
    );
    // Act
    await iniciarSesion(page);
    // Assert
    await expect(page.getByText('El correo no es válido').first()).toBeVisible({ timeout: 10_000 });
    await expect(page).not.toHaveURL(/#\/proyectos/);
  });

  test('lista vacía: una persona sin proyectos ve el aviso y no una pantalla en blanco', async ({ page }) => {
    // Arrange: stubs de un login correcto de un usuario base (rol 1005) y de 0 proyectos
    await page.route('**/users/2fa/check', (route) =>
      respuestaJson(route, { success: true, message: 'ok', data: { requires_2fa: false } }),
    );
    await page.route('**/users/login', (route) =>
      respuestaJson(route, {
        success: true,
        message: 'ok',
        data: {
          access_token: 'token-simulado',
          usuario: { id_user: 'usr-e2e', nombre: 'Persona', apellido: 'Prueba', mail: 'persona@raccord.test', id_rol: 1005 },
        },
      }),
    );
    const proyectos = espiar(page, '**/users/*/projects', (route) =>
      respuestaJson(route, { success: true, message: 'ok', data: [] }),
    );
    // Act
    await iniciarSesion(page);
    // Assert (estado): llegó a proyectos y muestra el aviso de lista vacía
    await expect(page).toHaveURL(/#\/proyectos/);
    await expect(page.getByText('Todavía no tienes proyectos asignados.').first()).toBeVisible({ timeout: 10_000 });
    // Assert (comportamiento): pidió la lista de ESE usuario y de ningún otro.
    // Observación: la app la pide 2 veces al entrar; no se fija el número.
    expect(proyectos.llamadas).toBeGreaterThan(0);
    expect(new Set(proyectos.urls)).toEqual(new Set(['/users/usr-e2e/projects']));
  });
});
