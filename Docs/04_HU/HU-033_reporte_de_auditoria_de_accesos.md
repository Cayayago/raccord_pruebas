# HU-033 — Reporte de Auditoría de Accesos

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-037 |
| Título | Reporte de Auditoría de Accesos |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociado | RF-037 |

---

## Historia

*Como* Productor de Línea,
*quiero* generar reportes filtrados del log de auditoría,
*para* investigar accesos sospechosos o una posible filtración de material confidencial.

## Criterios de Aceptación

- El reporte permite filtrar por usuario, rango de fechas, tipo de acción y resultado.
- Cada registro muestra timestamp, usuario, acción, IP, dispositivo y resultado.
- El reporte se puede exportar en Excel, y su propia generación queda registrada en el log.
