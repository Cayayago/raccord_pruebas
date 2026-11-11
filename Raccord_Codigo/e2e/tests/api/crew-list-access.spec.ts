import { test, expect } from '@playwright/test';
import { auth, credenciales, DENEGADO, login, PROJECT_ID, Rol } from '../helpers';

// Regresión: la Crew List usa GET /users/project/{id}, que antes
// respondía 403 ("No tienes acceso a este módulo") por revisar solo el
// módulo "roles" y no "crew_list".
test.describe('Crew List — acceso al listado del proyecto', () => {
  test.skip(!PROJECT_ID, 'Falta PROJECT_ID en .env');

  const roles: Rol[] = ['ADMIN', 'DIRECTOR', 'JEFE', 'ONSET', 'USUARIO'];

  for (const rol of roles) {
    test(`${rol} obtiene el listado de personas del proyecto`, async ({ request }) => {
      test.skip(!credenciales(rol), `Sin credenciales de ${rol}`);
      const token = (await login(request, rol))!;
      const res = await request.get(`/users/project/${PROJECT_ID}`, { headers: auth(token) });
      expect(res.status(), `rol ${rol}`).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
    });
  }

  test('sin token el listado es rechazado', async ({ request }) => {
    const res = await request.get(`/users/project/${PROJECT_ID}`);
    expect(DENEGADO).toContain(res.status());
  });
});
