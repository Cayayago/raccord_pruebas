# RNF-011 — Tiempo de Entrega de Notificaciones Push de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-011 |
| Título | Tiempo de Entrega de Notificaciones Push de Calendario |
| Categoría | Rendimiento / Funcionalidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-019, RF-022 |

---

**Descripción**: El sistema debe enviar notificaciones push a usuarios afectados en menos de 30 segundos cuando se crea, modifica o cancela un evento en el calendario.

**Métrica**:
- Tiempo de entrega < 30 segundos (p90)
- Medido desde que se guarda cambio en calendario hasta que notificación llega a dispositivo del usuario
- Para todos los usuarios afectados (hasta 50 usuarios)
- Incluye notificaciones: Normal, Urgente, Crítica


**Aplica a**:
- RF-022 (Notificaciones Push Instantáneas)
- RF-019 (Modificación de eventos)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:
- Modificar evento que afecta a 30 usuarios
- Registrar timestamp de modificación
- Verificar timestamp de recepción en 30 dispositivos
- Calcular diferencia
- Verificar p90 < 30 segundos
