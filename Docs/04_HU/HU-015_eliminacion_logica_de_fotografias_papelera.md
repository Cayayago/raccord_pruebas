# HU-015 — Eliminación Lógica de Fotografías (Papelera)

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-016 |
| Título | Eliminación Lógica de Fotografías (Papelera) |
| Prioridad | Media |
| Estado | Pendiente |
| RF asociado | RF-016 |

---

## Historia

*Como* Script (continuista),
*quiero* poder eliminar una fotografía sin perderla definitivamente,
*para* poder recuperarla si me equivoco al borrarla.

## Criterios de Aceptación

- Solo director y jefe de departamento  pueden eliminar o restaurar fotografías.
- Al eliminar, la fotografía se mueve a una papelera visible solo para director y jefe de departamento, sin borrarse del almacenamiento.
- La fotografía puede restaurarse durante 30 días; pasado ese plazo se elimina de forma permanente y automática.
- Toda eliminación y restauración queda registrada en el log de auditoría.
