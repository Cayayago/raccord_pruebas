# HU-004 — Sistema de Notificaciones por Email

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-004 |
| Título | Sistema de Notificaciones por Email |
| Prioridad | Crítica |
| Estado | Completada |
| RF asociado | RF-004 |

---

## Historia

*Como* usuario del sistema,
*quiero* recibir por correo las notificaciones de eventos críticos (activación de cuenta, código 2FA, recuperación de contraseña, cambios de calendario, comunicados),
*para* enterarme a tiempo sin tener que revisar la plataforma constantemente.

## Criterios de Aceptación

- El sistema selecciona la plantilla correcta según el tipo de notificación y genera el contenido dinámico.
- Si el envío falla, reintenta hasta 3 veces con espera exponencial (1s, 2s, 4s).
- Tras 3 intentos fallidos se registra el error y se notifica a los administradores.
- Cada envío exitoso queda registrado en el log de notificaciones con su marca de tiempo.
