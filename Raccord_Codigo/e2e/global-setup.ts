import { expect } from '@playwright/test';
import { auth, contextoApi, crearEmpresa, crearProyecto } from './tests/support/datos';

/**
 * Semana 8 — siembra por API el proyecto con un usuario por rol que usan los
 * tests de la S1 (login, notificaciones, papelera, Crew List).
 *
 * Antes esos tests leían un proyecto y unos usuarios ya existentes desde `.env`
 * y, sin ellos, se SALTABAN: en el CI saltaban 24 tests y el job salía en verde
 * sin probarlos (el "CI que miente"). Ahora, si `PROJECT_ID` no está definido, el
 * setup los crea con valores únicos y los deja en `process.env`, que es lo que ya
 * leen `tests/helpers.ts` y `auth-flujos.spec.ts`. Si el equipo define su propio
 * `.env`, se respeta y no se siembra nada.
 *
 * Roles por proyecto (app/utils/permissions.py): 1001 Administrador, 1002 Director,
 * 1003 Jefe de Departamento, 1004 Onset, 1005 Usuario.
 */
const ROLES_INVITADOS = { DIRECTOR: 1002, JEFE: 1003, ONSET: 1004, USUARIO: 1005 } as const;

export default async function globalSetup() {
  if (process.env.PROJECT_ID) return;

  const api = await contextoApi();
  try {
    const admin = await crearEmpresa(api);
    const proyecto = await crearProyecto(api, admin);
    process.env.PROJECT_ID = proyecto.idProject;
    process.env.ADMIN_MAIL = admin.mail;
    process.env.ADMIN_PASS = admin.contrasena;

    for (const [rol, idRol] of Object.entries(ROLES_INVITADOS)) {
      // Cada persona es una cuenta propia con contraseña conocida; el Administrador
      // la suma al proyecto con el rol que toca. "Invitar" a un usuario que ya
      // existe solo crea el vínculo con el proyecto (no necesita correo ni
      // contraseña temporal).
      const persona = await crearEmpresa(api);
      const res = await api.post('/users/invite', {
        headers: auth(admin.token),
        data: {
          invitados: [
            { nombre_completo: `Persona ${rol}`, mail: persona.mail, id_departamento: 'sin-departamento', id_rol: idRol },
          ],
          id_project: proyecto.idProject,
          id_client: admin.idCliente,
        },
      });
      const cuerpo = await res.json();
      expect(res.status(), `invitar ${rol}: ${cuerpo.message}`).toBe(200);
      expect(cuerpo.success, `invitar ${rol}: ${cuerpo.message}`).toBe(true);
      process.env[`${rol}_MAIL`] = persona.mail;
      process.env[`${rol}_PASS`] = persona.contrasena;
    }
  } finally {
    await api.dispose();
  }
}
