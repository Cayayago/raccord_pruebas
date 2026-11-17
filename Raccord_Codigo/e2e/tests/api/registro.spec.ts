import { test, expect } from '@playwright/test';

// Semana 1 — Flujo de REGISTRO de empresa + usuario (Deiver).
// Flujo distinto a los de login/sesión: crea datos reales, así que cada
// corrida usa correos únicos (Date.now()).
//
// OJO: el backend limita POST /register a 5 intentos cada 5 minutos por
// IP. Este archivo hace 4 registros; si lo corres dos veces seguidas,
// espera 5 minutos o verás 429.

const unico = Date.now();
const dominio = 'raccord-e2e.com'; // ".test" lo rechaza la validación de correo

function datosRegistro(sufijo: string, cambios: Record<string, string> = {}) {
  return {
    razon_social: `Productora E2E ${unico}-${sufijo}`,
    representante_legal: 'Ana Ruiz',
    email_empresa: `empresa.${unico}.${sufijo}@${dominio}`,
    document: 'NIT',
    // Único por registro: el NIT de la empresa no se puede repetir en la BD.
    id_document: `${String(unico).slice(-8)}${sufijo.charCodeAt(0)}`,
    nombre: 'Ana',
    apellido: 'Ruiz',
    mail: `ana.${unico}.${sufijo}@${dominio}`,
    msisdn: '3001234567',
    contrasena: 'Clave$egura123',
    ...cambios,
  };
}

test.describe.configure({ mode: 'serial' });

test.describe('Registro de empresa y usuario', () => {
  const principal = datosRegistro('a');

  test('registro válido crea la cuenta y permite iniciar sesión', async ({ request }) => {
    // Arrange
    const datos = principal;

    // Act
    const res = await request.post('/register', { data: datos });

    // Assert: queda registrada...
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success, body.message).toBe(true);
    expect(body.data.mail).toBe(datos.mail);
    expect(body.data.id_cliente).toBeTruthy();

    // ...y la persona puede entrar con esa contraseña
    const login = await request.post('/users/login', { data: { mail: datos.mail, contrasena: datos.contrasena } });
    const sesion = await login.json();
    expect(sesion.success, sesion.message).toBe(true);
    expect(sesion.data.access_token).toBeTruthy();
  });

  test('no permite registrar dos veces el mismo correo de usuario', async ({ request }) => {
    // Arrange: otra empresa, pero el MISMO correo personal del test anterior
    const datos = datosRegistro('b', { mail: principal.mail });

    // Act
    const res = await request.post('/register', { data: datos });

    // Assert
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(body.error).toBe('DUPLICATE_USER');
  });

  test('rechaza contraseña de 7 caracteres y correo inválido con 422', async ({ request }) => {
    // Arrange: valor límite de la contraseña (mínimo 8) y un correo mal formado
    const datos = datosRegistro('c', { contrasena: 'Ab$1234', mail: 'esto-no-es-un-correo' });

    // Act
    const res = await request.post('/register', { data: datos });

    // Assert: FastAPI/Pydantic devuelve el detalle de cada campo inválido
    expect(res.status()).toBe(422);
    const campos = (await res.json()).detail.map((e: { loc: string[] }) => e.loc.at(-1));
    expect(campos).toEqual(expect.arrayContaining(['contrasena', 'mail']));
  });

  // HALLAZGO (semana 1): la política de contraseñas (RF-006: mayúscula,
  // minúscula, número y carácter especial) SOLO se valida en la app
  // Flutter. Llamando a la API directamente se registra "12345678".
  // test.fail() marca este test como "falla esperada": cuando el backend
  // valide la política, Playwright avisará para quitar esta marca.
  test('el backend rechaza una contraseña que no cumple la política', async ({ request }) => {
    test.fail(true, 'HALLAZGO: el backend no valida la política de contraseñas (RF-006)');

    // Arrange: 8 caracteres, solo números
    const datos = datosRegistro('d', { contrasena: '12345678' });

    // Act
    const res = await request.post('/register', { data: datos });

    // Assert
    const body = await res.json();
    expect(body.success).not.toBe(true);
  });
});
