import { test, expect } from '@playwright/test';
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
    await campo(page, 'E-mail').fill(correo);
    await campo(page, 'Contraseña').fill('Incorrecta123!');
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
    await campo(page, 'E-mail').fill(MAIL!);
    await campo(page, 'Contraseña').fill(PASS!);
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

  test('recuperación de contraseña pasa al paso del código', async ({ page }) => {
    test.skip(!MAIL, 'Define ADMIN_MAIL en .env');
    // Arrange
    await abrirLogin(page);
    await page.getByRole('button', { name: /olvidaste tu contraseña/i }).click();
    await expect(page.getByText('¿Olvidaste tu contraseña?')).toBeVisible();
    // Act
    await campo(page, 'Correo electrónico').fill(MAIL!);
    await page.getByRole('button', { name: 'Enviar código' }).click();
    // Assert
    await expect(page.getByText('Restablecer contraseña').first()).toBeVisible();
    await expect(campo(page, 'Código')).toBeVisible();
  });
});
