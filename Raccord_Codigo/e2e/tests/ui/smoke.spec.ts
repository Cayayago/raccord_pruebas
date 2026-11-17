import { test, expect } from '@playwright/test';
import { abrirApp, abrirLogin, campo } from './flutter';

// Flutter Web dibuja en canvas; las pruebas usan el árbol de semántica.
test.describe('UI web — humo', () => {
  test('la app carga y monta Flutter', async ({ page }) => {
    // Arrange
    const errores: string[] = [];
    page.on('pageerror', (e) => errores.push(e.message));
    // Act
    const res = await page.goto('/');
    // Assert
    expect(res?.status()).toBe(200);
    await expect(page).toHaveTitle(/raccord/i);
    await page.locator('flutter-view, flt-glass-pane').first().waitFor({ state: 'attached', timeout: 20_000 });
    expect(errores, `errores JS: ${errores.join(' | ')}`).toHaveLength(0);
  });

  test('la pantalla inicial muestra el formulario de login', async ({ page }) => {
    // Arrange / Act
    await abrirLogin(page);
    // Assert
    await expect(campo(page, 'Contraseña')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Ingresar' })).toBeVisible();
  });

  test('sin sesión no se accede al dashboard por URL directa', async ({ page }) => {
    // Arrange / Act
    await abrirApp(page, '/#/dashboard');
    // Assert: se muestra el login y NO el contenido del dashboard
    await expect(campo(page, 'E-mail')).toBeVisible();
    await expect(page.getByText('Resumen del proyecto')).toHaveCount(0);
  });
});
