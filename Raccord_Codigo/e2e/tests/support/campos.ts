import { expect, type Locator, type Page } from '@playwright/test';

/**
 * Escribe en cualquier campo de Flutter con el teclado y confirma que el valor
 * quedó exacto. `fill` no es confiable en Flutter Web: pone el valor en el
 * <input> pero el framework no siempre lo registra (se vio el campo de
 * contraseña "lleno" y el formulario respondiendo que estaba vacío, sin enviar
 * la petición). Reintenta el campo entero hasta cumplirse, sin pausas fijas.
 */
export async function escribirEn(page: Page, campo: Locator, texto: string) {
  await expect(async () => {
    await campo.click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.type(texto);
    await expect(campo).toHaveValue(texto, { timeout: 1_000 });
  }).toPass({ timeout: 15_000 });
}

/**
 * Escribe en un campo de un diálogo de Flutter y confirma DOS cosas:
 *  1. que el valor quedó exacto (Flutter tarda unos milisegundos en aceptar
 *     teclas tras el enfoque y se perdían las primeras letras), y
 *  2. que FLUTTER lo registró: mientras el campo está vacío se llama como su
 *     hint; en cuanto el framework recibe texto deja de llamarse así. Leer el
 *     value del <input> no basta: se vio el campo "lleno" y el formulario
 *     respondiendo "Requerido".
 * Si algo no se cumple, se repite el campo entero (seleccionar todo y escribir)
 * dentro de toPass: reintenta hasta cumplirse, sin pausas fijas.
 *
 * `posicion` es el índice del textbox dentro del diálogo; `hint` el texto que
 * Flutter muestra mientras el campo está vacío.
 */
export async function escribirEnDialogo(page: Page, posicion: number, hint: string, texto: string) {
  const campo = page.getByRole('dialog').getByRole('textbox').nth(posicion);
  await expect(async () => {
    await campo.click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.type(texto);
    await expect(campo).toHaveValue(texto, { timeout: 1_000 });
    await expect(page.getByRole('textbox', { name: hint })).toHaveCount(0, { timeout: 1_000 });
  }).toPass({ timeout: 15_000 });
}
