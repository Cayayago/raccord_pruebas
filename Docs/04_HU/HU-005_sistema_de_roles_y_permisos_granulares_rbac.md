# HU-005 — Sistema de Roles y Permisos Granulares (RBAC)

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-005 |
| Título | Sistema de Roles y Permisos Granulares (RBAC) |
| Prioridad | Crítica |
| Estado | Completado |
| RF asociado | RF-005 |

---

## Historia

*Como* Administrador Total,
*quiero* que el sistema controle el acceso a cada módulo según el rol de cada usuario,
*para* que cada persona del equipo solo pueda ver y hacer lo que le corresponde.

## Criterios de Aceptación

- El sistema valida el rol del usuario contra la matriz de permisos antes de ejecutar cualquier acción.
- Si el rol no tiene permiso, la acción se deniega y se muestra "No tiene permisos para realizar esta acción".
- Todo intento de acceso, permitido o denegado, queda registrado en el log de auditoría.
- El sistema nunca permite eliminar ni cambiar el rol del último Administrador Total activo.
