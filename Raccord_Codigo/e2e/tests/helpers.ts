import { APIRequestContext, expect } from '@playwright/test';

export type Rol = 'ADMIN' | 'DIRECTOR' | 'JEFE' | 'ONSET' | 'USUARIO';

export const PROJECT_ID = process.env.PROJECT_ID ?? '';

export function credenciales(rol: Rol): { mail: string; pass: string } | null {
  const mail = process.env[`${rol}_MAIL`];
  const pass = process.env[`${rol}_PASS`];
  return mail && pass ? { mail, pass } : null;
}

/** Inicia sesión por API y devuelve el JWT (null si no hay credenciales). */
export async function login(request: APIRequestContext, rol: Rol): Promise<string | null> {
  const c = credenciales(rol);
  if (!c) return null;
  const res = await request.post('/users/login', { data: { mail: c.mail, contrasena: c.pass } });
  expect(res.status(), `login ${rol}`).toBe(200);
  const body = await res.json();
  expect(body.success, `login ${rol}: ${body.message}`).toBe(true);
  return body.data.access_token as string;
}

export const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

/** El backend responde 401/403 por HTTP al faltar permisos. */
export const DENEGADO = [401, 403];
