import { test, expect } from '@playwright/test';
import { auth, credenciales, DENEGADO, login, PROJECT_ID, Rol } from '../helpers';

// Papelera de fotos: ven la papelera Admin (solo lectura), Director y Jefe.
// Onset y Usuario no.
test.describe('Papelera de fotos — permisos de vista', () => {
  test.skip(!PROJECT_ID, 'Falta PROJECT_ID en .env');

  const puedenVer: Rol[] = ['ADMIN', 'DIRECTOR', 'JEFE'];
  const noPuedenVer: Rol[] = ['ONSET', 'USUARIO'];

  for (const rol of puedenVer) {
    test(`${rol} puede ver la papelera`, async ({ request }) => {
      test.skip(!credenciales(rol), `Sin credenciales de ${rol}`);
      const token = (await login(request, rol))!;
      const res = await request.get(`/fotos/papelera/${PROJECT_ID}`, { headers: auth(token) });
      expect(res.status()).toBe(200);
      expect((await res.json()).success).toBe(true);
    });
  }

  for (const rol of noPuedenVer) {
    test(`${rol} NO puede ver la papelera`, async ({ request }) => {
      test.skip(!credenciales(rol), `Sin credenciales de ${rol}`);
      const token = (await login(request, rol))!;
      const res = await request.get(`/fotos/papelera/${PROJECT_ID}`, { headers: auth(token) });
      expect(DENEGADO).toContain(res.status());
    });
  }

  test('sin token la papelera es rechazada', async ({ request }) => {
    const res = await request.get(`/fotos/papelera/${PROJECT_ID}`);
    expect(DENEGADO).toContain(res.status());
  });
});
