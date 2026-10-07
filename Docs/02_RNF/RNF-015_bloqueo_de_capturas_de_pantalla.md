# RNF-015 — Bloqueo de Capturas de Pantalla

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-015 |
| Título | Bloqueo de Capturas de Pantalla |
| Categoría | Seguridad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-010, RF-015, RF-027 |

---

**Descripción**: El sistema debe deshabilitar capturas de pantalla a nivel de sistema operativo en la app móvil (iOS/Android) cuando se visualizan contenidos sensibles (fotografías, guiones). En la app de escritorio (Windows/macOS) y en la página web de ingreso, donde el sistema operativo/navegador no ofrece una API equivalente para bloquear capturas de forma confiable, se aplican controles de mejor esfuerzo (deshabilitar clic derecho y atajos de captura/impresión dentro de la app), quedando la marca de agua dinámica (RF-015) como la protección principal en esas plataformas.

**Métrica**:
- 100% de pantallas sensibles protegidas en móviles:

        iOS: FLAG_SECURE equivalente
        Android: WindowManager.LayoutParams.FLAG_SECURE
        Pantalla negra si usuario intenta captura
- En escritorio (Windows/macOS): clic derecho deshabilitado dentro de la app, atajos de captura/impresión interceptados cuando la app tiene foco (mejor esfuerzo, no garantizado a nivel de SO)
- En la página web de ingreso: clic derecho deshabilitado, atajos de teclado bloqueados (Ctrl+S, Ctrl+P, PrtScr, Ctrl+Shift+S) — aplica solo a esa página, no a contenido sensible (no se muestran fotos/guiones ahí)


**Aplica a**:
- RF-010 (Visualización de fotografías)
- RF-015 (Marca de agua)
- RF-027 (Visualización de guiones)

**Estándar/Norma**: ISO/IEC 27001

**Método de Verificación**:
- Pruebas manuales en dispositivos iOS intentando captura de pantalla
- Pruebas manuales en dispositivos Android intentando captura
- Verificar pantalla se pone negra
- En escritorio: intentar clic derecho y atajos de captura/impresión dentro de la app → deben estar bloqueados o interceptados; documentar explícitamente que esto es un disuasivo y no un bloqueo garantizado por el SO
