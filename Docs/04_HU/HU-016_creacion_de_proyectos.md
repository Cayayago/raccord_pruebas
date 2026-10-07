# HU-016 — Creación de Proyectos

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-017 |
| Título | Creación de Proyectos |
| Prioridad | Crítica |
| Estado | Completada |
| RF asociado | RF-017 |

---

## Historia

*Como* Administrador Total,
*quiero* crear un nuevo proyecto con su información básica,
*para* tener un contenedor donde organizar todas las fotografías, guiones y el calendario de esa producción.

## Criterios de Aceptación

- Solo un Administrador Total puede crear proyectos, y el sistema valida que el nombre no esté duplicado.
- El proyecto queda creado en estado "Activo" con un ID único y su calendario inicializado.
- El creador queda asignado automáticamente como Administrador Total del proyecto.
- La creación queda registrada en el log de auditoría.
