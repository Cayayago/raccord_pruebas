# HU-027 — Desglose Editable de Guion

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-031 |
| Título | Desglose Editable de Guion |
| Prioridad | Media |
| Estado | Completado |
| RF asociado | RF-031 |

---

## Historia

*Como* Primera Ayudante de Dirección,
*quiero* que el sistema me sugiera locaciones, vehículos y efectos especiales a partir de palabras clave del guion y me permita capturar el resto del desglose manualmente,
*para* armar el desglose de la escena más rápido sin depender de un lector completamente automático que no existe en el sistema.

## Criterios de Aceptación

- El sistema detecta y sugiere locaciones (encabezados "INT."/"EXT.") y menciones de vehículos o efectos especiales mediante palabras clave, sin usar inteligencia artificial.
- Personajes, vestuario y utilería se capturan siempre de forma manual, ya que el texto libre del guion es demasiado ambiguo para sugerirlos de forma confiable con reglas simples.
- El usuario puede confirmar, editar o descartar cualquier sugerencia, y añadir los elementos que falten manualmente.
- El desglose confirmado se vincula automáticamente con la gestión de desgloses de escena (RF-020).
- El desglose se puede exportar en PDF o Excel.
