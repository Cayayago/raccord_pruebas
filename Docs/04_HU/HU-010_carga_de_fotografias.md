# HU-010 — Carga de Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-010 |
| Título | Carga de Fotografías |
| Prioridad | Crítica |
| Estado | Completada |
| RF asociado | RF-010 |

---

## Historia

*Como* Script (continuista),
*quiero* subir fotografías de continuidad desde mi celular o tablet completando los metadatos de escena, toma y personaje,
*para* dejar un registro visual confiable que evite errores de continuidad.

## Criterios de Aceptación

- El sistema exige completar proyecto, escena, toma, personaje, tipo de detalle y estado de continuidad antes de guardar.
- El sistema genera automáticamente la nomenclatura estandarizada y aplica marca de agua con usuario, timestamp y proyecto.
- Si el archivo excede el tamaño permitido, se comprime automáticamente conservando calidad visual.
- Si no hay conexión, la fotografía se guarda localmente y se sincroniza automáticamente al reconectar.
- La subida queda registrada en el log de auditoría.
