# RNF-032 — Compatibilidad de la Página Web de Ingreso con Navegadores Modernos

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-032 |
| Título | Compatibilidad de la Página Web de Ingreso con Navegadores Modernos |
| Categoría | Compatibilidad |
| Prioridad | Media |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: Tras la migración del frontend a Flutter (ver ADR de stack de frontend), la única superficie que sigue siendo una página web es el punto de entrada ("Ingresar"): en PC abre el flujo de autenticación en el navegador; en tablets/celulares, el mismo enlace abre la app Flutter nativa vía Universal Links/App Links sin pasar por el navegador. Esta página de ingreso debe funcionar sin errores en navegadores modernos (Chrome, Firefox, Safari, Edge) versión actual y una versión anterior, sin necesidad de soportar Internet Explorer. El resto de la aplicación (fotografías, calendario, guiones, etc.) corre dentro de la app Flutter nativa y no depende de un navegador.

**Métrica**:

- Compatibilidad con:

        Chrome/Edge (Chromium) ≥ 90
        Firefox ≥ 88
        Safari ≥ 14
- 100% de funcionalidad de la página de ingreso en cada navegador
- Sin errores de JavaScript en consola
- Renderizado visual correcto
- NO se soporta Internet Explorer


**Aplica a**: Página web de ingreso / autenticación (no aplica al resto de la app, que es Flutter nativo)

**Estándar/Norma**:

- W3C Web Standards
- ECMAScript 2020+

**Método de Verificación**:
- Pruebas manuales en cada navegador
- Verificar funcionalidad crítica en cada navegador: Login y redirección/apertura de la app (o descarga desde la store si no está instalada)
- Verificar consola sin errores
