# HU-021 — Notificaciones Push Instantáneas de Cambios de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-022 |
| Título | Notificaciones Push Instantáneas de Cambios de Calendario |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociado | RF-022 |

---

## Historia

*Como* miembro del equipo,
*quiero* recibir una notificación push apenas cambie algo en el calendario que me afecte,
*para* no enterarme tarde de un cambio de locación u horario.

## Criterios de Aceptación

- El sistema identifica automáticamente a los usuarios afectados por la creación, modificación o cancelación de un evento1
- La notificación se entrega en menos de 30 segundos e incluye qué cambió, quién lo hizo y un enlace directo al evento.
- El nivel de prioridad (Normal/Urgente/Crítico) determina el color, sonido y vibración de la notificación.
- Si la entrega falla, el sistema reintenta hasta 3 veces antes de alertar a los administradores.
