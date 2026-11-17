import { test, expect } from '@playwright/test';
import { auth, credenciales, DENEGADO, login, PROJECT_ID, Rol } from '../helpers';

const url = `/notificaciones/project/${PROJECT_ID}`;

test.describe('Notificaciones', () => {
  test.skip(!PROJECT_ID, 'Falta PROJECT_ID en .env');

  const publicarOk: Rol[] = ['DIRECTOR', 'JEFE'];
  const publicarNo: Rol[] = ['ADMIN', 'ONSET', 'USUARIO'];

  for (const rol of publicarOk) {
    test(`${rol} puede publicar una notificación general`, async ({ request }) => {
      test.skip(!credenciales(rol), `Sin credenciales de ${rol}`);
      const token = (await login(request, rol))!;
      const texto = `Prueba automática ${rol} ${Date.now()}`;
      const res = await request.post(url, {
        headers: auth(token),
        multipart: { tipo_alcance: 'general', texto, origen: 'manual' },
      });
      expect(res.status()).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
      expect(body.data.texto).toBe(texto);
      expect(body.data.tipo_alcance).toBe('general');

      // El autor la ve en su bandeja y ya figura como leída.
      const lista = await (await request.get(url, { headers: auth(token) })).json();
      const propia = lista.data.find((n: any) => n.id_notificacion === body.data.id_notificacion);
      expect(propia).toBeTruthy();
      expect(propia.leida).toBe(true);
    });
  }

  for (const rol of publicarNo) {
    test(`${rol} NO puede publicar notificaciones`, async ({ request }) => {
      test.skip(!credenciales(rol), `Sin credenciales de ${rol}`);
      const token = (await login(request, rol))!;
      const res = await request.post(url, {
        headers: auth(token),
        multipart: { tipo_alcance: 'general', texto: 'No debería publicarse', origen: 'manual' },
      });
      expect(DENEGADO).toContain(res.status());
    });
  }

  test('texto vacío es rechazado', async ({ request }) => {
    test.skip(!credenciales('DIRECTOR'), 'Sin credenciales de DIRECTOR');
    const token = (await login(request, 'DIRECTOR'))!;
    const res = await request.post(url, {
      headers: auth(token),
      multipart: { tipo_alcance: 'general', texto: '   ', origen: 'manual' },
    });
    const body = await res.json();
    expect(body.success).toBe(false);
  });

  test('alcance específico sin departamentos es rechazado', async ({ request }) => {
    test.skip(!credenciales('DIRECTOR'), 'Sin credenciales de DIRECTOR');
    const token = (await login(request, 'DIRECTOR'))!;
    const res = await request.post(url, {
      headers: auth(token),
      multipart: { tipo_alcance: 'especifica', texto: 'Sin departamentos', origen: 'manual' },
    });
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(body.error).toBe('NO_DEPARTMENTS');
  });

  test('alcance inválido es rechazado', async ({ request }) => {
    test.skip(!credenciales('DIRECTOR'), 'Sin credenciales de DIRECTOR');
    const token = (await login(request, 'DIRECTOR'))!;
    const res = await request.post(url, {
      headers: auth(token),
      multipart: { tipo_alcance: 'todos', texto: 'Alcance raro', origen: 'manual' },
    });
    expect((await res.json()).success).toBe(false);
  });

  test('un miembro lee una notificación general y baja su contador de no leídas', async ({ request }) => {
    test.skip(!credenciales('DIRECTOR') || !credenciales('ONSET'), 'Faltan DIRECTOR u ONSET');
    const dir = (await login(request, 'DIRECTOR'))!;
    const pub = await (
      await request.post(url, {
        headers: auth(dir),
        multipart: { tipo_alcance: 'general', texto: `Lectura ${Date.now()}`, origen: 'plan_rodaje' },
      })
    ).json();
    expect(pub.success).toBe(true);
    const id = pub.data.id_notificacion;

    const onset = (await login(request, 'ONSET'))!;
    const antes = (await (await request.get(`${url}/no-leidas`, { headers: auth(onset) })).json()).data.no_leidas;
    expect(antes).toBeGreaterThanOrEqual(1);

    const leer = await request.post(`/notificaciones/${id}/leer`, { headers: auth(onset) });
    expect(leer.status()).toBe(200);

    const despues = (await (await request.get(`${url}/no-leidas`, { headers: auth(onset) })).json()).data.no_leidas;
    expect(despues).toBe(antes - 1);
  });
});
