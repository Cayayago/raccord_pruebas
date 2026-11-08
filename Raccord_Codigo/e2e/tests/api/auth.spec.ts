import { test, expect } from '@playwright/test';
import { auth, credenciales, DENEGADO, login, PROJECT_ID } from '../helpers';

test.describe('Autenticación y sesión', () => {
  test('login con contraseña incorrecta no entrega token', async ({ request }) => {
    const res = await request.post('/users/login', {
      data: { mail: 'no.existe@raccord.test', contrasena: 'incorrecta123' },
    });
    const body = await res.json();
    // Con credenciales inválidas nunca se declara éxito ni se entrega token
    // (el backend puede responder 200 con success=false, 401 o 429 por rate limit).
    expect(body.success).not.toBe(true);
    expect(body.data?.access_token).toBeUndefined();
  });

  test('endpoint protegido sin token es rechazado', async ({ request }) => {
    const res = await request.get(`/notificaciones/project/${PROJECT_ID || 'x'}`);
    expect(DENEGADO).toContain(res.status());
  });

  test('token inválido es rechazado', async ({ request }) => {
    const res = await request.get(`/notificaciones/project/${PROJECT_ID || 'x'}`, {
      headers: auth('token.falso.invalido'),
    });
    expect(DENEGADO).toContain(res.status());
  });

  test('logout revoca el token', async ({ request }) => {
    test.skip(!credenciales('DIRECTOR') || !PROJECT_ID, 'Falta DIRECTOR o PROJECT_ID en .env');
    const token = (await login(request, 'DIRECTOR'))!;

    const antes = await request.get(`/notificaciones/project/${PROJECT_ID}`, { headers: auth(token) });
    expect(antes.status()).toBe(200);

    const out = await request.post('/users/logout', { headers: auth(token) });
    expect(out.status()).toBe(200);

    const despues = await request.get(`/notificaciones/project/${PROJECT_ID}`, { headers: auth(token) });
    expect(DENEGADO).toContain(despues.status());
  });
});
