import { test, expect } from '@playwright/test';
import { abrirLogin, campo } from './flutter';

// Semana 1 — UI del formulario de REGISTRO (Deiver).
// Solo valida lo que ve la persona antes de enviar: no crea cuentas
// (el registro real se prueba por API en tests/api/registro.spec.ts).

test.describe('UI — registro de empresa', () => {
  test.beforeEach(async ({ page }) => {
    await abrirLogin(page);
    await page.getByRole('tab', { name: 'Registrar' }).click();
    await expect(campo(page, 'Razón Social')).toBeVisible();
  });

  test('con el formulario vacío el botón Registrar está deshabilitado y explica por qué', async ({ page }) => {
    // Arrange: formulario recién abierto (beforeEach)

    // Act: no se llena nada

    // Assert
    await expect(page.getByRole('button', { name: 'Registrar', exact: true })).toBeDisabled();
    await expect(page.getByText('Completa todos los campos requeridos para registrarte.')).toBeVisible();
  });

  test('una contraseña débil muestra las reglas que le faltan', async ({ page }) => {
    // Arrange
    const contrasena = campo(page, 'Contraseña');

    // Act: solo minúsculas, menos de 8 caracteres
    await contrasena.fill('abc');

    // Assert: aparecen las reglas de RF-006 que aún no se cumplen
    await expect(page.getByText('Mínimo 8 caracteres')).toBeVisible();
    await expect(page.getByText('Una letra mayúscula')).toBeVisible();
    await expect(page.getByText('Un número')).toBeVisible();
    await expect(page.getByText('Un carácter especial')).toBeVisible();
  });
});
