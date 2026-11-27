import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { escribirEnDialogo } from '../support/campos';
import { abrirConSesion } from '../support/sesion-ui';
import { auth, contextoApi, crearEmpresa, crearProyecto, unico, type Empresa } from '../support/datos';

// Semana 7 — Flujo crítico 3: PROYECTO (crear y abrir) (Javier).
//
// Por qué es crítico: sin proyecto activo no hay guion, escenas ni personajes;
// es la puerta de entrada a todo el producto. Si un proyecto se duplica o se
// abre el equivocado, el equipo trabaja sobre datos que no son los suyos.
//
// Arrange por API (empresa y proyectos únicos por test); por la UI solo se prueba
// "Gestión de Proyectos": la persona llega SIN proyecto activo (como justo
// después de iniciar sesión) y debe crearlo o elegirlo.

let api: APIRequestContext;
let empresa: Empresa;

test.beforeEach(async () => {
  api = await contextoApi();
  empresa = await crearEmpresa(api);
});

test.afterEach(async () => {
  await api.dispose();
});

const HINT_NOMBRE = 'Nombre de la serie, película u otro proyecto audiovisual';

/** Nombres de los proyectos del usuario según la API (la verdad, no la pantalla). */
async function proyectosPorApi(nombre: string): Promise<number> {
  const res = await api.get(`/users/${empresa.idUser}/projects`, { headers: auth(empresa.token) });
  const cuerpo = await res.json();
  expect(cuerpo.success, cuerpo.message).toBe(true);
  return cuerpo.data.filter((p: { project_name: string }) => p.project_name === nombre).length;
}

// La fila de un proyecto se expone con su nombre como etiqueta accesible; se
// admite botón o grupo porque Flutter elige el rol según el widget.
const filaDe = (page: Page, nombre: string) =>
  page.getByRole('button', { name: nombre }).or(page.getByRole('group', { name: nombre })).first();

async function abrirDialogoCrear(page: Page) {
  await abrirConSesion(page, empresa, null, '/#/proyectos');
  await page.getByRole('button', { name: 'Crear Proyecto' }).click();
  await expect(page.getByRole('dialog').getByRole('textbox').first()).toBeVisible();
}

test.describe('UI — gestión de proyectos', () => {
  test('al elegir un proyecto de la lista se abre su dashboard y queda como proyecto activo', async ({ page }) => {
    const elegido = await crearProyecto(api, empresa, `Elegido ${unico()}`);
    await crearProyecto(api, empresa, `Otro ${unico()}`);
    await abrirConSesion(page, empresa, null, '/#/proyectos');

    await filaDe(page, elegido.nombre).click();

    await expect(page).toHaveURL(/#\/ROJO-PROVOCADO/); // ROJO PROVOCADO S8 (revertir)
    // El encabezado del dashboard lleva el nombre del proyecto activo, no el de otro.
    await expect(page.getByRole('banner', { name: elegido.nombre })).toBeVisible();
    const activo = await page.evaluate(() => window.localStorage.getItem('flutter.raccord_project_id'));
    expect(JSON.parse(activo ?? 'null')).toBe(elegido.idProject);
  });

  test('sin nombre muestra el error y no crea ningún proyecto', async ({ page }) => {
    await abrirDialogoCrear(page);

    await page.getByRole('dialog').getByRole('button', { name: 'Crear Proyecto' }).click();

    // Flutter marca el campo como inválido y además lo anuncia en una región
    // aria-live: por eso "Requerido" aparece dos veces y se valida el campo.
    await expect(page.getByRole('textbox', { name: HINT_NOMBRE })).toHaveAttribute('aria-invalid', 'true');
    await expect(page.getByRole('dialog').getByText('Requerido').first()).toBeVisible();
    const res = await api.get(`/users/${empresa.idUser}/projects`, { headers: auth(empresa.token) });
    expect((await res.json()).data).toHaveLength(0);
  });

  // HALLAZGO (semana 7): un doble clic en "Crear Proyecto" enviaba DOS POST y
  // creaba el proyecto dos veces, aunque el botón se deshabilita mientras guarda
  // (el segundo clic llega antes del redibujado). Corregido en
  // project_form_screen.dart (`if (_loading) return;`); mientras el frontend en
  // :8081 no se reconstruya, test.fail() lo deja documentado.
  test('un doble clic en Crear Proyecto con la red lenta crea un solo proyecto', async ({ page }) => {
    test.fail(
      process.env.E2E_FRONT_CORREGIDO !== 'true',
      'HALLAZGO S7: doble envío en crear proyecto (corregido en el código, falta reconstruir el frontend)',
    );
    await page.route('**/projects/create', async (route) => {
      const respuesta = await route.fetch();
      await new Promise((resolver) => setTimeout(resolver, 700));
      await route.fulfill({ response: respuesta });
    });
    const posts: string[] = [];
    page.on('request', (peticion) => {
      if (peticion.method() === 'POST' && peticion.url().endsWith('/projects/create')) posts.push(peticion.url());
    });
    const nombre = `Doble ${unico()}`;
    await abrirDialogoCrear(page);
    await escribirEnDialogo(page, 0, HINT_NOMBRE, nombre);
    // Los desplegables de Formato y Género son obligatorios.
    for (const [hint, opcion] of [
      ['Selecciona un formato', 'Largometraje'],
      ['Selecciona un género', 'Drama'],
    ]) {
      // El desplegable se expone como botón con su hint y sus opciones como menuitem.
      await page.getByRole('dialog').getByRole('button', { name: hint }).click();
      await page.getByRole('menuitem', { name: opcion, exact: true }).click();
    }

    await page.getByRole('dialog').getByRole('button', { name: 'Crear Proyecto' }).dblclick();

    await expect.poll(() => proyectosPorApi(nombre), { timeout: 10_000 }).toBeGreaterThan(0);
    expect(posts).toHaveLength(1);
    expect(await proyectosPorApi(nombre)).toBe(1);
    await expect(filaDe(page, nombre)).toBeVisible();
  });
});
