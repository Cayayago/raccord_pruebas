# HU-011 — Historial y versionado de fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-011 |
| Título | Historial y versionado de fotografías |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociado | RF-011 |

---

## Historia

*Como* Script (continuista),
*quiero* que el sistema versione automáticamente las fotografías repetidas de una misma toma y me permita ver y restaurar el historial,
*para* no perder nunca una referencia visual anterior.

## Criterios de Aceptación

- El sistema genera una nomenclatura única por fotografía e incrementa la versión automáticamente si ya existe la misma base (V1, V2...).
- Las versiones anteriores nunca se eliminan; quedan marcadas como históricas.
- El usuario puede ver el historial completo de versiones con fecha, autor y comentarios.
- Solo el Script puede restaurar una versión anterior como actual, y la acción queda en el log de auditoría.
