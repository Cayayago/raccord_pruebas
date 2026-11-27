import { test, expect, type Page } from '@playwright/test';
import { escribirEn } from '../support/campos';
import { abrirLogin, campo } from './flutter';

// Semana 1 — E2E de los flujos de autenticación (Flutter Web).
// Flutter dibuja en canvas: se activa el árbol de semántica para usar
// roles/etiquetas (AppTextField expone Semantics(label: ...)).

const MAIL = process.env.ADMIN_MAIL;
const PASS = process.env.ADMIN_PASS;


test.describe('UI — autenticación', () => {
  test('login con contraseña incorrecta muestra error y no entra', async ({ page }) => {
    // Arrange
    await abrirLogin(page);
    const correo = `noexiste.${Date.now()}@raccord.test`;
    // Act
    await escribirEn(page, campo(page, 'E-mail'), correo);
    await escribirEn(page, campo(page, 'Contraseña'), 'Incorrecta123!');
    // La petición termina bien (200) o falla (p. ej. 429 por rate limit, sin CORS):
    // en ambos casos el usuario no debe entrar.
    const esLogin = (r: { url(): string; method(): string }) =>
      r.url().includes('/users/') && r.method() === 'POST';
    const peticion = Promise.race([
      page.waitForEvent('requestfinished', esLogin),
      page.waitForEvent('requestfailed', esLogin),
    ]);
    await page.getByRole('button', { name: 'Ingresar' }).click();
    await peticion;
    // Assert: no entra (el mensaje es un SnackBar efímero; se verifica el resultado)
    await expect(page).not.toHaveURL(/#\/proyectos/);
    await expect(campo(page, 'E-mail')).toBeVisible();
    await expect(campo(page, 'Contraseña')).toBeVisible();
  });

  test('login válido llega a la selección de proyecto', async ({ page }) => {
    test.skip(!MAIL || !PASS, 'Define ADMIN_MAIL y ADMIN_PASS en .env');
    // Arrange
    await abrirLogin(page);
    // Act
    await escribirEn(page, campo(page, 'E-mail'), MAIL!);
    await escribirEn(page, campo(page, 'Contraseña'), PASS!);
    await page.getByRole('button', { name: 'Ingresar' }).click();
    // Assert
    await expect(page).toHaveURL(/#\/proyectos/);
  });

  test('formulario de login valida campos vacíos', async ({ page }) => {
    // Arrange
    await abrirLogin(page);
    // Act
    await page.getByRole('button', { name: 'Ingresar' }).click();
    // Assert
    await expect(page.getByText('Ingresa tu correo').first()).toBeVisible();
    await expect(page.getByText('Ingresa tu contraseña').first()).toBeVisible();
  });

  // El envío del correo es una dependencia externa (SMTP): ni el CI ni la BD de
  // pruebas tienen servidor de correo, y el backend responde "Error al enviar
  // correo" (comportamiento correcto desde la S5). Por eso la respuesta se simula
  // con page.route: lo que se prueba aquí es lo que hace la PANTALLA con cada
  // respuesta, no que el correo salga de verdad (eso lo cubre
  // tests/test_dobles_correo.py con un doble de Notifier).
  const respuestaRecuperar = (ok: boolean) => ({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify(
      ok
        ? { success: true, message: 'Código de recuperación enviado al correo', data: null }
        : { success: false, message: 'Error al enviar correo', error: 'MAIL_ERROR', data: null },
    ),
  });

  async function pedirCodigo(page: Page, ok: boolean) {
    await page.route('**/users/recover-password', (route) => route.fulfill(respuestaRecuperar(ok)));
    await abrirLogin(page);
    await page.getByRole('button', { name: /olvidaste tu contraseña/i }).click();
    await expect(page.getByText('¿Olvidaste tu contraseña?')).toBeVisible();
    await escribirEn(page, campo(page, 'Correo electrónico'), MAIL ?? 'ana@raccord-e2e.com');
    await page.getByRole('button', { name: 'Enviar código' }).click();
  }

  test('recuperación de contraseña pasa al paso del código', async ({ page }) => {
    // Arrange + Act: el correo sale bien
    await pedirCodigo(page, true);
    // Assert
    await expect(page.getByText('Restablecer contraseña').first()).toBeVisible();
    await expect(campo(page, 'Código')).toBeVisible();
  });

  test('si el correo no sale, avisa y no pasa al paso del código', async ({ page }) => {
    // Arrange + Act: el servidor de correo falla
    await pedirCodigo(page, false);
    // Assert: se muestra el error y se queda en "Recuperar acceso"
    await expect(page.getByText('Error al enviar correo').first()).toBeVisible();
    await expect(page.getByText('Restablecer contraseña')).toHaveCount(0);
  });
});
