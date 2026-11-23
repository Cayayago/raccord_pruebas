import { expect, test } from '@playwright/test';
import { auth, crearEmpresa, crearProyecto } from '../support/datos';

// Semana 7 — comprueba la BASE de la suite: que cada test prepare sus propios
// datos por API, en la BD de pruebas, y que dos tests en paralelo no se pisen.
// Si esto falla, ningún flujo E2E es confiable.
test.describe('Base E2E — datos propios por test', () => {
  test('una empresa recién creada puede iniciar sesión y crear su proyecto', async ({ request }) => {
    // Arrange
    const empresa = await crearEmpresa(request);

    // Act
    const proyecto = await crearProyecto(request, empresa);

    // Assert: el proyecto aparece en la lista de ESA persona
    const res = await request.get(`/users/${empresa.idUser}/projects`, { headers: auth(empresa.token) });
    const cuerpo = await res.json();
    expect(cuerpo.success, cuerpo.message).toBe(true);
    expect(cuerpo.data.map((p: { id_project: string }) => p.id_project)).toContain(proyecto.idProject);
  });

  test('dos empresas no ven los proyectos una de la otra', async ({ request }) => {
    // Arrange: dos empresas distintas, cada una con su proyecto
    const a = await crearEmpresa(request);
    const b = await crearEmpresa(request);
    const proyectoA = await crearProyecto(request, a);
    const proyectoB = await crearProyecto(request, b);

    // Act
    const res = await request.get(`/users/${a.idUser}/projects`, { headers: auth(a.token) });
    const ids = (await res.json()).data.map((p: { id_project: string }) => p.id_project);

    // Assert
    expect(ids).toContain(proyectoA.idProject);
    expect(ids).not.toContain(proyectoB.idProject);
  });

  test('un token de una empresa no abre el proyecto de otra', async ({ request }) => {
    // Arrange
    const a = await crearEmpresa(request);
    const b = await crearEmpresa(request);
    const proyectoB = await crearProyecto(request, b);

    // Act
    const res = await request.get(`/characters/project/${proyectoB.idProject}`, { headers: auth(a.token) });

    // Assert
    expect(res.status()).toBe(403);
  });
});
