import { type Page } from '@playwright/test';
import { abrirApp } from '../ui/flutter';
import { type Empresa } from './datos';

/**
 * Deja la app Flutter con la sesión YA iniciada y el proyecto activo, sin pasar
 * por el login en cada test (el login se prueba aparte, en su propio flujo).
 *
 * Flutter Web guarda SharedPreferences en localStorage con el prefijo "flutter."
 * y cada valor codificado como JSON. Se escribe antes de que cargue la app
 * (addInitScript), así `AuthSession.bootstrap()` la encuentra al arrancar.
 */
export async function abrirConSesion(
  page: Page,
  empresa: Empresa,
  proyecto: { idProject: string; nombre: string } | null,
  ruta: string,
  rol = 1001,
) {
  const claves: Record<string, unknown> = {
    raccord_token: empresa.token,
    raccord_user_id: empresa.idUser,
    raccord_user_nombre: 'Ana',
    raccord_user_apellido: 'Ruiz',
    raccord_user_mail: empresa.mail,
    raccord_user_rol: rol,
    raccord_user_client: empresa.idCliente,
    // Con `proyecto: null` la persona llega sin proyecto activo, como justo
    // después de iniciar sesión, y debe elegirlo en "Gestión de Proyectos".
    ...(proyecto && {
      raccord_project_id: proyecto.idProject,
      raccord_project_name: proyecto.nombre,
      raccord_project_rol: rol,
    }),
    // Sin esto, el primer ingreso muestra el recorrido guiado obligatorio.
    [`registration_date_${empresa.idUser}`]: new Date().toISOString(),
    [`has_completed_tour_dashboard_${empresa.idUser}`]: true,
    [`has_completed_tour_projects_${empresa.idUser}`]: true,
  };

  await page.addInitScript((valores) => {
    for (const [clave, valor] of Object.entries(valores)) {
      window.localStorage.setItem(`flutter.${clave}`, JSON.stringify(valor));
    }
  }, claves);

  await abrirApp(page, ruta);
}
