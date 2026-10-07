# HU-001 — Auto-registro del primer administrador

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-001 |
| Título | Auto-registro del primer administrador |
| Prioridad | Crítica |
| Estado | completado |
| RF asociado | RF-001 |

---

## Historia

*Como* Productor de Línea o Jefe de Producción (primer usuario),
*quiero* que el sistema me registre automáticamente como Administrador Total al implementar Raccord por primera vez,
*para* tener control total del proyecto desde el primer momento, sin depender de que alguien más me dé acceso.

## Criterios de Aceptación

- El sistema detecta que la base de datos no tiene usuarios y habilita el formulario de auto-registro sin restricciones.
- Al completar el formulario, el usuario queda creado con rol "Administrador Total" y estado "Activo".
- Se crea automáticamente un proyecto inicial y el usuario queda vinculado a él.
- Si ya existe al menos un usuario, el sistema deshabilita el auto-registro y muestra "Contacte al administrador del sistema para obtener acceso".
- Se envía un correo de confirmación y la creación queda registrada en el log de auditoría.
