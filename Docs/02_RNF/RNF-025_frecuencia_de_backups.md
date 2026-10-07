# RNF-025 — Frecuencia de Backups

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-025 |
| Título | Frecuencia de Backups |
| Categoría | Confiabilidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe realizar backups automáticos cada hora durante períodos de rodaje activo, almacenando copias en al menos dos ubicaciones geográficas distintas.

**Métrica**:
- Backups automáticos cada 1 hora (24 backups/día)
- Incluye:

        Base de datos completa (PostgreSQL)
        Fotografías subidas en la última hora
        Configuración del sistema
- Almacenamiento en 2+ ubicaciones geográficas diferentes
- Retención:

        Backups horarios: 7 días
        Backups diarios: 30 días
        Backups semanales: 3 meses

**Aplica a**:

- Base de datos PostgreSQL
- Storage de fotografías (S3 o equivalente)
- Configuración del sistema

**Estándar/Norma**: ISO/IEC 27001 - Backup

**Método de Verificación**:

- Configurar cron jobs para backups horarios
- Verificar 24 backups generados en 24 horas
- Verificar backups en 2 ubicaciones geográficas
- Intentar restauración de backup (simulación de desastre)
