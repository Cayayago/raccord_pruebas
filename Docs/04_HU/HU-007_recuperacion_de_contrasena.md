# HU-007 — Recuperación de Contraseña

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-007 |
| Título | Recuperación de Contraseña |
| Prioridad | Alta |
| Estado | Completada |
| RF asociado | RF-007 |

---

## Historia

*Como* usuario que olvidó su contraseña,
*quiero* solicitar un enlace de recuperación a mi correo,
*para* restablecer el acceso a mi cuenta sin depender de un administrador.

## Criterios de Aceptación

- El sistema envía el enlace de recuperación solo si el correo existe en la base de datos.
- El enlace deja de ser válido después de usarse una vez.
- Al definir la nueva contraseña se aplican las reglas de RF-006 y se cierran todas las sesiones activas del usuario.
- Se envía un correo de confirmación cuando el cambio fue exitoso.
