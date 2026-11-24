import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { contextoApi, crearEmpresa, unico, type Empresa } from '../support/datos';
import { PantallaAcceso, type DatosRegistro } from '../support/pantalla-acceso';

// Semana 7 — Flujo crítico 1: REGISTRO + LOGIN (Deiver).
// Es la puerta de entrada: si falla, ninguna productora nueva puede empezar a
// usar Raccord. Por la UI solo se hace lo que el test prueba; las cuentas que
// el test necesita ya existentes se crean por API (support/datos.ts), con
// valores únicos para poder correr en paralelo y con --repeat-each.

// Ventana alta: el formulario de registro es largo y Flutter solo expone en el
// árbol de accesibilidad lo que está cerca de la pantalla.
test.use({ viewport: { width: 1280, height: 2000 } });

let api: APIRequestContext;

test.beforeEach(async () => {
  api = await contextoApi();
});

test.afterEach(async () => {
  await api.dispose();
});

const DOMINIO = 'raccord-e2e.com';

function datosNuevos(): DatosRegistro {
  const id = unico();
  return {
    razonSocial: `Productora UI ${id}`,
    nit: `8${process.pid}${Date.now().toString().slice(-7)}`,
    emailEmpresa: `empresa.ui.${id}@${DOMINIO}`,
    nombres: 'Deiver',
    apellidos: 'Prueba',
    mail: `deiver.ui.${id}@${DOMINIO}`,
    celular: '3001234567',
    contrasena: 'Clave$egura123',
  };
}

/** ¿El backend acepta estas credenciales? (estado real, no solo lo que muestra la UI) */
async function loginPorApi(mail: string, contrasena: string): Promise<boolean> {
  const res = await api.post('/users/login', { data: { mail, contrasena } });
  return (await res.json()).success === true;
}

/** Cuenta las peticiones POST a una ruta del backend mientras corre el test. */
function contarPosts(page: Page, ruta: string): string[] {
  const posts: string[] = [];
  page.on('request', (peticion) => {
    if (peticion.method() === 'POST' && new URL(peticion.url()).pathname === ruta) posts.push(peticion.url());
  });
  return posts;
}

/** Retrasa la respuesta de un POST para simular red lenta (sin waitForTimeout en el test). */
async function retrasarPost(page: Page, ruta: string, ms: number) {
  await page.route(`**${ruta}`, async (route) => {
    if (route.request().method() !== 'POST') return route.continue();
    const respuesta = await route.fetch();
    await new Promise((resolver) => setTimeout(resolver, ms));
    await route.fulfill({ response: respuesta });
  });
}

test.describe('UI — registro de una productora nueva', () => {
  test('el registro por la UI crea la cuenta y lleva a registrar el primer proyecto', async ({ page }) => {
    // Arrange
    const pantalla = new PantallaAcceso(page);
    const datos = datosNuevos();
    await pantalla.abrir();
    await pantalla.irARegistro();
    await pantalla.llenarRegistro(datos);

    // Act
    await pantalla.botonRegistrar.click();

    // Assert: la persona sigue al paso obligatorio y la cuenta existe de verdad
    await expect(page).toHaveURL(/#\/registrar-proyecto/);
    expect(await loginPorApi(datos.mail, datos.contrasena)).toBe(true);
  });

  test('registrarse con un correo que ya existe muestra el error y no entra', async ({ page }) => {
    // Arrange: la cuenta ya existe (creada por API)
    const existente: Empresa = await crearEmpresa(api);
    const pantalla = new PantallaAcceso(page);
    await pantalla.abrir();
    await pantalla.irARegistro();
    await pantalla.llenarRegistro({ ...datosNuevos(), mail: existente.mail });

    // Act
    await pantalla.botonRegistrar.click();

    // Assert: el mensaje del backend llega a la persona y se queda en el formulario
    await expect(pantalla.mensaje('El correo del usuario ya está registrado')).toBeVisible();
    await expect(page).not.toHaveURL(/#\/registrar-proyecto/);
    await expect(pantalla.botonRegistrar).toBeVisible();
  });

  test('un doble clic en Registrar con la red lenta envía un solo registro', async ({ page }) => {
    // Parte 3 (defectos de tiempos): el botón se deshabilita al redibujar, pero
    // el segundo clic puede llegar antes.
    const pantalla = new PantallaAcceso(page);
    const datos = datosNuevos();
    await retrasarPost(page, '/register', 1_500);
    const registros = contarPosts(page, '/register');
    await pantalla.abrir();
    await pantalla.irARegistro();
    await pantalla.llenarRegistro(datos);

    await pantalla.botonRegistrar.dblclick();

    await expect(page).toHaveURL(/#\/registrar-proyecto/, { timeout: 15_000 });
    expect(registros).toHaveLength(1);
  });
});

test.describe('UI — inicio de sesión', () => {
  test('una cuenta existente entra por la UI y llega a sus proyectos', async ({ page }) => {
    // Arrange
    const empresa = await crearEmpresa(api);
    const pantalla = new PantallaAcceso(page);
    await pantalla.abrir();
    await pantalla.llenarIngreso(empresa.mail, empresa.contrasena);

    // Act
    await pantalla.botonIngresar.click();

    // Assert
    await expect(page).toHaveURL(/#\/proyectos/);
  });

  test('con la contraseña equivocada muestra por qué y no entra', async ({ page }) => {
    // Arrange
    const empresa = await crearEmpresa(api);
    const pantalla = new PantallaAcceso(page);
    await pantalla.abrir();
    await pantalla.llenarIngreso(empresa.mail, 'Equivocada$123');

    // Act
    await pantalla.botonIngresar.click();

    // Assert: el mensaje del backend (INVALID_CREDENTIALS) se ve y no entra
    await expect(pantalla.mensaje(/Verifica tu correo y tu contraseña/)).toBeVisible();
    await expect(page).not.toHaveURL(/#\/proyectos/);
    await expect(pantalla.botonIngresar).toBeVisible();
  });

  test('un doble clic en Ingresar con la red lenta inicia sesión una sola vez', async ({ page }) => {
    const empresa = await crearEmpresa(api);
    const pantalla = new PantallaAcceso(page);
    await retrasarPost(page, '/users/login', 1_500);
    const logins = contarPosts(page, '/users/login');
    await pantalla.abrir();
    await pantalla.llenarIngreso(empresa.mail, empresa.contrasena);

    await pantalla.botonIngresar.dblclick();

    await expect(page).toHaveURL(/#\/proyectos/, { timeout: 15_000 });
    expect(logins).toHaveLength(1);
  });
});
