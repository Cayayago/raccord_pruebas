# HU-009 — Log de Auditoría de Accesos y Acciones

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-009 |
| Título | Log de Auditoría de Accesos y Acciones |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociado | RF-009 |

---

## Historia

*Como* Administrador Total,
*quiero* que el sistema registre automáticamente cada acceso y acción crítica de los usuarios,
*para* poder auditar la actividad del sistema y detectar posibles filtraciones.

## Criterios de Aceptación

- Cada acción crítica (login, visualización de fotos/guiones, cambios de calendario, exportaciones, cambios de permisos) genera un registro con usuario, timestamp, IP, dispositivo y resultado.
- Los registros del log no se pueden editar ni eliminar, solo insertar.
- Los registros se conservan 90 días activos, se archivan automáticamente después y se purgan a los 15 meses.
