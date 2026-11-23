import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { escribirEnDialogo } from '../support/campos';
import { abrirConSesion } from '../support/sesion-ui';
import { auth, contextoApi, crearEmpresa, crearProyecto, unico, type Empresa } from '../support/datos';

// Semana 7 — Flujo crítico 2: PERSONAJES del proyecto (Javier).
//
// Por qué es crítico: es lo que el equipo de preproducción usa a diario; un
// personaje que no se guarda, o que se guarda dos veces, contamina escenas,
// actores y desgloses que dependen de él.
//
// Cada test crea su empresa, usuario y proyecto POR API (valores únicos) y entra
// a la app con la sesión ya iniciada: por la UI solo se prueba el flujo de
// personajes, nada más.
//
// Flutter expone cada campo como un textbox llamado como su hint, y `fill` no es
// confiable: se enfoca el campo y se escribe con el teclado (aprendizaje S5).

let api: APIRequestContext;
let empresa: Empresa;
let proyecto: { idProject: string; nombre: string };

test.beforeEach(async () => {
  api = await contextoApi();
  empresa = await crearEmpresa(api);
  proyecto = await crearProyecto(api, empresa);
});

test.afterEach(async () => {
  await api.dispose();
});

const HINT = { codigo: 'Ej: P001, P002', nombre: 'Nombre del personaje', edad: 'Edad del personaje' };

/**
 * Escribe en un campo de Flutter y confirma DOS cosas:
 *  1. que el valor quedó exacto (Flutter tarda unos milisegundos en aceptar
 *     teclas tras el enfoque y se perdían las primeras letras), y
 *  2. que FLUTTER lo registró: mientras el campo está vacío se llama como su
 *     hint; en cuanto el framework recibe texto deja de llamarse así. Leer el
 *     value del <input> no basta: se vio el campo "lleno" y el formulario
 *     respondiendo "Requerido".
 * Si algo no se cumple, se repite el campo entero (seleccionar todo y escribir)
 * dentro de toPass: reintenta hasta cumplirse, sin pausas fijas.
 */
const escribir = escribirEnDialogo;

async function llenarFormulario(page: Page, datos: { codigo: string; nombre: string; edad: string }) {
  await escribir(page, 0, HINT.codigo, datos.codigo);
  if (datos.nombre) await escribir(page, 1, HINT.nombre, datos.nombre);
  await escribir(page, 2, HINT.edad, datos.edad);
}

// Cada fila de la lista es un grupo con nombre "P001 Laura 35 años": el texto
// va como etiqueta accesible, por eso no sirve getByText.
const filaDe = (page: Page, nombre: string) => page.getByRole('group', { name: nombre });

async function abrirFormulario(page: Page) {
  await abrirConSesion(page, empresa, proyecto, '/#/personajes');
  await page.getByRole('button', { name: 'Crear Personaje' }).click();
  await expect(page.getByRole('dialog').getByRole('textbox')).toHaveCount(3);
}

async function personajesPorApi(nombre: string): Promise<number> {
  const res = await api.get(`/characters/project/${proyecto.idProject}`, { headers: auth(empresa.token) });
  const cuerpo = await res.json();
  expect(cuerpo.success, cuerpo.message).toBe(true);
  return cuerpo.data.filter((p: { nombre: string }) => p.nombre === nombre).length;
}

test.describe('UI — personajes del proyecto', () => {
  test('un personaje creado por la UI aparece en la lista y queda guardado', async ({ page }) => {
    // Arrange
    const nombre = `Laura ${unico()}`;
    await abrirFormulario(page);

    // Act
    await llenarFormulario(page, { codigo: 'P001', nombre, edad: '35' });
    await page.getByRole('button', { name: 'Guardar', exact: true }).click();

    // Assert: se ve en la lista y la BD lo tiene UNA sola vez
    await expect(filaDe(page, nombre)).toBeVisible();
    expect(await personajesPorApi(nombre)).toBe(1);
  });

  test('sin nombre muestra el error y no guarda nada', async ({ page }) => {
    // Arrange
    await abrirFormulario(page);
    await llenarFormulario(page, { codigo: 'P002', nombre: '', edad: '40' });

    // Act
    await page.getByRole('button', { name: 'Guardar', exact: true }).click();

    // Assert: el formulario sigue abierto con el mensaje de validación
    await expect(page.getByText('Requerido').first()).toBeVisible();
    const res = await api.get(`/characters/project/${proyecto.idProject}`, { headers: auth(empresa.token) });
    expect((await res.json()).data).toHaveLength(0);
  });

  // HALLAZGO (semana 7): un doble clic en Guardar enviaba DOS POST y creaba el
  // personaje dos veces. Corregido en characters_screen.dart (`if (_loading) return;`),
  // pero la imagen del frontend que corre en :8081 se construye aparte: mientras
  // no se reconstruya con el cambio, este test falla; test.fail() lo deja
  // documentado y avisa cuando el defecto desaparezca (ver tests de registro S1).
  test('un doble clic en Guardar con la red lenta crea un solo personaje', async ({ page }) => {
    // Con E2E_FRONT_CORREGIDO=true (frontend ya reconstruido con la corrección) el test
    // corre normal y debe pasar; sin esa variable se espera la falla del hallazgo.
    test.fail(
      process.env.E2E_FRONT_CORREGIDO !== 'true',
      'HALLAZGO S7: doble envío en el formulario de personajes (corregido en el código, falta reconstruir el frontend)',
    );
    // Arrange: la respuesta del POST tarda, como con wifi débil en el set. La
    // petición SÍ llega al servidor; solo se retrasa lo que ve el navegador.
    await page.route('**/characters', async (route) => {
      if (route.request().method() !== 'POST') return route.continue();
      const respuesta = await route.fetch();
      await new Promise((resolver) => setTimeout(resolver, 700));
      await route.fulfill({ response: respuesta });
    });
    const posts: string[] = [];
    page.on('request', (peticion) => {
      if (peticion.method() === 'POST' && peticion.url().endsWith('/characters')) posts.push(peticion.url());
    });
    const nombre = `Doble ${unico()}`;
    await abrirFormulario(page);
    await llenarFormulario(page, { codigo: 'P003', nombre, edad: '28' });

    // Act
    await page.getByRole('button', { name: 'Guardar', exact: true }).dblclick();

    // Assert, en orden de importancia:
    // 1) el personaje quedó guardado (se espera sin pausas fijas, consultando la API);
    await expect.poll(() => personajesPorApi(nombre), { timeout: 10_000 }).toBeGreaterThan(0);
    // 2) salió UNA sola petición y existe UN solo registro. Con el defecto salían dos
    //    POST y el segundo `Navigator.pop` cerraba también la pantalla de Personajes
    //    (la persona terminaba en el Dashboard);
    expect(posts).toHaveLength(1);
    expect(await personajesPorApi(nombre)).toBe(1);
    // 3) y la persona sigue en la lista, viendo su personaje.
    await expect(filaDe(page, nombre)).toHaveCount(1);
  });
});
