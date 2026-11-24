import { type Locator, type Page } from '@playwright/test';
import { abrirApp, campo } from '../ui/flutter';
import { escribirEn } from './campos';

/** Datos que pide el formulario "Registrar" (empresa + persona). */
export interface DatosRegistro {
  razonSocial: string;
  nit: string;
  emailEmpresa: string;
  nombres: string;
  apellidos: string;
  mail: string;
  celular: string;
  contrasena: string;
}

/**
 * Objeto de página de la pantalla de acceso (pestañas Ingresar / Registrar).
 * Semana 7: varios tests repiten los mismos pasos de esta pantalla, así que
 * viven aquí. Sin aserciones: solo pasos; cada test decide qué verificar.
 */
export class PantallaAcceso {
  constructor(private readonly page: Page) {}

  get botonIngresar(): Locator {
    return this.page.getByRole('button', { name: 'Ingresar', exact: true });
  }

  get botonRegistrar(): Locator {
    return this.page.getByRole('button', { name: 'Registrar', exact: true });
  }

  /** Mensaje efímero (SnackBar) que la app muestra tras enviar. */
  mensaje(texto: string | RegExp): Locator {
    return this.page.getByText(texto).first();
  }

  async abrir() {
    await abrirApp(this.page, '/');
    await campo(this.page, 'E-mail').waitFor();
  }

  async llenarIngreso(mail: string, contrasena: string) {
    await escribirEn(this.page, campo(this.page, 'E-mail'), mail);
    await escribirEn(this.page, campo(this.page, 'Contraseña'), contrasena);
  }

  async irARegistro() {
    await this.page.getByRole('tab', { name: 'Registrar' }).click();
    await campo(this.page, 'Razón Social').waitFor();
  }

  /** Llena todo el formulario de registro y acepta los términos. */
  async llenarRegistro(datos: DatosRegistro) {
    const p = this.page;
    // La razón social se guarda en minúsculas (LowerCaseTextFormatter).
    await escribirEn(p, campo(p, 'Razón Social'), datos.razonSocial.toLowerCase());
    await escribirEn(p, campo(p, 'Nº Documento'), datos.nit);
    await escribirEn(p, campo(p, 'Email Empresa'), datos.emailEmpresa);
    await escribirEn(p, campo(p, 'Nombres'), datos.nombres);
    await escribirEn(p, campo(p, 'Apellidos'), datos.apellidos);
    await escribirEn(p, campo(p, 'Email Personal'), datos.mail);
    await escribirEn(p, campo(p, 'Celular'), datos.celular);
    await escribirEn(p, campo(p, 'Contraseña'), datos.contrasena);
    await escribirEn(p, campo(p, 'Confirmar Contraseña'), datos.contrasena);
    await p.getByRole('checkbox').click();
  }
}
