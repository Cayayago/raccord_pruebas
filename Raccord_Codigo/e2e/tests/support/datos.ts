import { APIRequestContext, expect, request as playwrightRequest } from '@playwright/test';

/** Dominio aceptado por la validación de correo (".test" lo rechaza). */
const DOMINIO = 'raccord-e2e.com';

let contador = 0;

/**
 * Valor único por test, incluso con --repeat-each y varios workers en paralelo:
 * hora + proceso + contador. Así dos corridas simultáneas nunca chocan en
 * correos, NIT ni nombres.
 */
export function unico(): string {
  contador += 1;
  return `${Date.now().toString(36)}${process.pid.toString(36)}${contador}`;
}

export interface Empresa {
  mail: string;
  contrasena: string;
  token: string;
  idUser: string;
  idCliente: string;
}

/**
 * Prepara por API una empresa nueva con su usuario administrador y la sesión
 * iniciada. Es el "Arrange" de todos los E2E: no depende de lo que ya haya en
 * la BD y el test solo prueba por la UI lo que le interesa.
 */
export async function crearEmpresa(request: APIRequestContext): Promise<Empresa> {
  const id = unico();
  const datos = {
    razon_social: `Productora E2E ${id}`,
    representante_legal: 'Ana Ruiz',
    email_empresa: `empresa.${id}@${DOMINIO}`,
    document: 'NIT',
    // Numérico (es un NIT) y con el pid del worker: con --repeat-each dos workers
    // podían generar el mismo valor en el mismo milisegundo y chocar ("Ya existe
    // una cuenta con ese documento").
    id_document: `9${process.pid}${Date.now().toString().slice(-7)}${contador}`,
    nombre: 'Ana',
    apellido: 'Ruiz',
    mail: `ana.${id}@${DOMINIO}`,
    msisdn: '3001234567',
    contrasena: 'Clave$egura123',
  };

  const registro = await request.post('/register', { data: datos });
  const cuerpo = await registro.json();
  expect(registro.status(), `registro: ${cuerpo.message}`).toBe(200);
  expect(cuerpo.success, cuerpo.message).toBe(true);

  const login = await request.post('/users/login', { data: { mail: datos.mail, contrasena: datos.contrasena } });
  const sesion = await login.json();
  expect(sesion.success, `login: ${sesion.message}`).toBe(true);

  return {
    mail: datos.mail,
    contrasena: datos.contrasena,
    token: sesion.data.access_token,
    idUser: cuerpo.data.id_user as string,
    idCliente: cuerpo.data.id_cliente,
  };
}

export const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

/** Crea un proyecto por API y deja al usuario como Administrador de él. */
export async function crearProyecto(request: APIRequestContext, empresa: Empresa, nombre = `Proyecto ${unico()}`) {
  const res = await request.post('/projects/create', {
    headers: auth(empresa.token),
    data: {
      project_name: nombre.slice(0, 45),
      formato_de_produccion: 'Largometraje',
      genero: 'Drama',
      id_client: empresa.idCliente,
      id_user: empresa.idUser,
    },
  });
  const cuerpo = await res.json();
  expect(res.status(), `proyecto: ${cuerpo.message}`).toBe(200);
  expect(cuerpo.success, cuerpo.message).toBe(true);
  return { idProject: cuerpo.data.id_project as string, nombre: cuerpo.data.project_name as string };
}

/** URL del backend de pruebas (misma regla que playwright.config.js). */
export const API_URL = (process.env.API_URL ?? 'http://127.0.0.1:8000').replace('localhost', '127.0.0.1');

/**
 * Contexto de API para los tests de UI: su `request` por defecto apunta al
 * frontend (8081), no al backend, así que el Arrange por API necesita el suyo.
 */
export async function contextoApi(): Promise<APIRequestContext> {
  return playwrightRequest.newContext({ baseURL: API_URL });
}
