# RNF-033 — Sincronización entre Dispositivos del Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-033 |
| Título | Sincronización entre Dispositivos del Usuario |
| Categoría | Compatibilidad / Funcionalidad |
| Prioridad | Media |
| Estado | Pendiente |
| RF asociados | RF-008, RF-021 |

---

**Descripción**: El sistema debe sincronizar automáticamente información del usuario entre todos sus dispositivos (preferencias, notas personales, configuración de interfaz) en menos de 30 segundos tras cambio.

**Métrica**:

- Sincronización automática en < 30 segundos
- Información sincronizada:

        Notas personales en calendario
        Preferencias de notificación
        Configuración de interfaz (modo oscuro, idioma)
        Sesión activa (login en dispositivo A visible en dispositivo B)
- Sincronización bidireccional entre:

        Tablet ↔ Smartphone
        Tablet ↔ Desktop
        Smartphone ↔ Desktop


**Aplica a**:
- RF-008 (Gestión de perfil)
- RF-021 (Notas personales)

**Estándar/Norma**: ISO/IEC 25010 - Interoperabilidad

**Método de Verificación**:
- Usuario logueado en tablet y smartphone simultáneamente
- Cambiar preferencia en tablet (ej: activar modo oscuro)
- Verificar cambio reflejado en smartphone en <30 segundos
- Repetir con 10 cambios diferentes
- Verificar 100% de sincronización exitosa
