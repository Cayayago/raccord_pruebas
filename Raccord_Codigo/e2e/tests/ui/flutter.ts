import { expect, type Page } from '@playwright/test';

/** Abre una ruta de Flutter Web y activa el árbol de accesibilidad (semántica). */
export async function abrirApp(page: Page, ruta = '/') {
  await page.goto(ruta);
  await page.locator('flutter-view, flt-glass-pane').first().waitFor({ state: 'attached', timeout: 20_000 });
  // Flutter dibuja en canvas: la semántica expone roles/etiquetas para los tests.
  await page.locator('flt-semantics-placeholder').evaluate((el: HTMLElement) => el.click());
}

/** Campo de texto de AppTextField: Flutter lo expone como grupo con la etiqueta y un textbox dentro. */
export function campo(page: Page, etiqueta: string) {
  return page.getByRole('group', { name: etiqueta, exact: true }).getByRole('textbox');
}

export async function abrirLogin(page: Page) {
  await abrirApp(page, '/');
  await expect(campo(page, 'E-mail')).toBeVisible();
}
