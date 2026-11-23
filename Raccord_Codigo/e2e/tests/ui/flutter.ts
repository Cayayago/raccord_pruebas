import { expect, type Page } from '@playwright/test';

/** Abre una ruta de Flutter Web y activa el árbol de accesibilidad (semántica). */
export async function abrirApp(page: Page, ruta = '/') {
  await page.goto(ruta);
  await page.locator('flutter-view, flt-glass-pane').first().waitFor({ state: 'attached', timeout: 20_000 });
  // Flutter dibuja en canvas: la semántica expone roles/etiquetas para los tests.
  await page.locator('flt-semantics-placeholder').evaluate((el: HTMLElement) => el.click());
}

/**
 * Campo de texto de AppTextField, por su etiqueta visible. Según la versión del
 * frontend que esté sirviendo :8081, Flutter lo expone de una de dos formas:
 *  - build con `Semantics(label)`: grupo con la etiqueta y un textbox dentro;
 *  - build anterior: el texto de la etiqueta suelto y, a continuación, el
 *    textbox (nombrado como su hint).
 * Se aceptan ambas para que los tests no dependan de qué imagen está corriendo.
 */
export function campo(page: Page, etiqueta: string) {
  const conGrupo = page.getByRole('group', { name: etiqueta, exact: true }).getByRole('textbox');
  const despuesDelTexto = page
    .getByText(etiqueta, { exact: true })
    .locator('xpath=following::*[self::input or self::textarea][1]');
  return conGrupo.or(despuesDelTexto);
}

export async function abrirLogin(page: Page) {
  await abrirApp(page, '/');
  await expect(campo(page, 'E-mail')).toBeVisible();
}
