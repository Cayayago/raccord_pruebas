# RNF-010 — Tiempo de Creación de Evento en Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-010 |
| Título | Tiempo de Creación de Evento en Calendario |
| Categoría | Rendimiento |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | RF-018, RF-019 |

---

**Descripción**: El sistema debe completar la creación de un evento en el calendario (incluyendo procesamiento y notificaciones) en menos de 3 segundos desde que usuario hace click en "Guardar".
**Métrica**:
- Tiempo total < 3 segundos (p95)
- Incluye: validación, creación en BD, cálculo de usuarios afectados
- NO incluye: envío de notificaciones push (ese es asíncrono, ver RNF-011)


**Aplica a**:
- RF-018 (Creación de eventos en calendario)
- RF-019 (Modificación de eventos)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:
- Crear 50 eventos consecutivos con 12 campos completos
- Medir tiempo desde click "Guardar" hasta mensaje confirmación
- Verificar p95 < 3 segundos
