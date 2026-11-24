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

  /**
   * Llena todo el formulario de registro y acepta los términos.
   *
   * Los campos se ubican por su POSICIÓN en el formulario y no por la etiqueta:
   * en el build web varios campos no exponen la etiqueta como grupo, sino el
   * hint como nombre accesible, y ese nombre desaparece en cuanto el campo
   * tiene texto. Por etiqueta, "Email Empresa" resolvía también el campo
   * anterior (Nº Documento). El orden del formulario es fijo (no hay campos
   * condicionales); "Tipo de documento" es un desplegable, no un textbox.
   */
  async llenarRegistro(datos: DatosRegistro) {
    const p = this.page;
    const caja = (posicion: number) => p.getByRole('textbox').nth(posicion);
    // La razón social se guarda en minúsculas (LowerCaseTextFormatter).
    await escribirEn(p, caja(0), datos.razonSocial.toLowerCase());
    await escribirEn(p, caja(1), datos.nit); //            Nº Documento
    await escribirEn(p, caja(2), datos.emailEmpresa); //   Email Empresa
    //                    3 = Dirección, 4 = Celular Empresa (opcionales)
    await escribirEn(p, caja(5), datos.nombres);
    await escribirEn(p, caja(6), datos.apellidos);
    await escribirEn(p, caja(7), datos.mail); //           Email Personal
    await escribirEn(p, caja(8), datos.celular);
    await escribirEn(p, caja(9), datos.contrasena);
    await escribirEn(p, caja(10), datos.contrasena); //    Confirmar Contraseña
    await p.getByRole('checkbox').click();
  }

  /** Hace clic en Ingresar y espera la respuesta del backend (sin pausas fijas). */
  async ingresarYEsperarRespuesta() {
    const respuesta = this.page.waitForResponse((r) => r.url().endsWith('/users/2fa/check'));
    await this.botonIngresar.click();
    return respuesta;
  }

  /** Hace clic en Registrar y espera la respuesta de /register. */
  async registrarYEsperarRespuesta() {
    const respuesta = this.page.waitForResponse(
      (r) => new URL(r.url()).pathname === '/register' && r.request().method() === 'POST',
    );
    await this.botonRegistrar.click();
    return respuesta;
  }
}
