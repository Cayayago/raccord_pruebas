import { expect, type Locator, type Page } from '@playwright/test';
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
    await this.llenarYConfirmar([
      [campo(this.page, 'E-mail'), mail],
      [campo(this.page, 'Contraseña'), contrasena],
    ]);
  }

  /**
   * Escribe cada campo y al final confirma TODOS juntos, reescribiendo el que
   * haya perdido su valor. En el CI se vio que, si Flutter no alcanza a mover
   * el foco, el texto de un campo cae en el anterior o se pierde (Apellidos
   * quedaba vacío y Registrar seguía deshabilitado). Sin pausas fijas: toPass
   * repite hasta que todo el formulario tenga lo que debe.
   */
  private async llenarYConfirmar(pares: Array<[Locator, string]>) {
    for (const [caja, texto] of pares) await escribirEn(this.page, caja, texto);
    await expect(async () => {
      for (const [caja, texto] of pares) {
        if ((await caja.inputValue()) !== texto) await escribirEn(this.page, caja, texto);
      }
      for (const [caja, texto] of pares) await expect(caja).toHaveValue(texto, { timeout: 1_000 });
    }).toPass({ timeout: 30_000 });
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
    await this.llenarYConfirmar([
      // Razón social, nombres y apellidos se guardan en minúsculas (LowerCaseTextFormatter).
      [caja(0), datos.razonSocial.toLowerCase()],
      [caja(1), datos.nit], //            Nº Documento
      [caja(2), datos.emailEmpresa], //   Email Empresa
      //            3 = Dirección, 4 = Celular Empresa (opcionales)
      [caja(5), datos.nombres],
      [caja(6), datos.apellidos],
      [caja(7), datos.mail], //           Email Personal
      [caja(8), datos.celular],
      [caja(9), datos.contrasena],
      [caja(10), datos.contrasena], //    Confirmar Contraseña
    ]);
    const terminos = p.getByRole('checkbox');
    await expect(async () => {
      if (!(await terminos.isChecked())) await terminos.click();
      await expect(terminos).toBeChecked({ timeout: 1_000 });
    }).toPass({ timeout: 10_000 });
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
