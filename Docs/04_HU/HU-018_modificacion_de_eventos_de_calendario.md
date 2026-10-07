# HU-018 — Modificación de Eventos de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-019 |
| Título | Modificación de Eventos de Calendario |
| Prioridad | Crítica |
| Estado | Completado |
| RF asociado | RF-019 |

---

## Historia

*Como* Primera Ayudante de Dirección,
*quiero* modificar un evento existente del calendario y que el sistema avise automáticamente a los afectados,
*para* evitar que alguien llegue a rodar con información desactualizada.

## Criterios de Aceptación

- El sistema detecta automáticamente qué campos cambiaron y guarda el valor anterior y el nuevo en el historial.
- Cambios en fecha, escenas, locación o personajes se consideran críticos por defecto.
- El sistema recalcula los usuarios afectados y envía notificaciones push según el nivel de prioridad.
- Los usuarios afectados quedan notificados en menos de 30 segundos.
