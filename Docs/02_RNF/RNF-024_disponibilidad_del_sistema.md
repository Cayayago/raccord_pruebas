# RNF-024 — Disponibilidad del Sistema

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-024 |
| Título | Disponibilidad del Sistema |
| Categoría | Disponibilidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe garantizar disponibilidad de 99.9% durante períodos de rodaje activo, con downtime máximo tolerable de 43 minutos por mes.

**Métrica**:
- Uptime ≥ 99.9% mensual
- Downtime máximo: 43.2 minutos/mes
- Medición 24/7 con herramienta de monitoreo
- Cálculo: (Tiempo total - Tiempo caído) / Tiempo total × 100


**Aplica a**:

- Toda la infraestructura del sistema
- Aplicaciones móviles y web
- API backend
- Base de datos
- Storage (S3)

**Estándar/Norma**:
- ISO/IEC 20000 - Service Management
- ITIL - Service Availability Management

**Método de Verificación**:
- Monitoreo continuo con Uptime Robot, Pingdom o similar
- Registro de incidentes y downtime
- Cálculo mensual de disponibilidad
- Verificar ≥ 99.9% durante 3 meses consecutivos
