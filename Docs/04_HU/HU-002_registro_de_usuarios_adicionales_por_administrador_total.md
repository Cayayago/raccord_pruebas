# HU-002 — Registro de Usuarios Adicionales por Administrador Total

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-002 |
| Título | Registro de Usuarios Adicionales por Administrador Total |
| Prioridad | Crítica |
| Estado | Completada |
| RF asociado | RF-002 |

---

## Historia

*Como* Administrador Total,
*quiero* registrar nuevos usuarios asignándoles rol, departamento y proyecto(s),
*para* ir construyendo y organizando el equipo de producción.

## Criterios de Aceptación

- Solo un usuario con rol Administrador Total puede ejecutar el registro.
- El sistema genera una contraseña temporal y crea el usuario en estado "Inactivo".
- Se envía un correo con las credenciales y el enlace de activación.
- Si el usuario no activa la cuenta en 48 horas, el registro se elimina automáticamente.
- La acción queda registrada en el log de auditoría.
