# RNF-003 — Tiempo de Entrega de Notificaciones (2FA, Recuperación)

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-003 |
| Título | Tiempo de Entrega de Notificaciones (2FA, Recuperación) |
| Categoría | Rendimiento |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-003, RF-004, RF-007, RF-022 |

---

**Descripción**: Las notificaciones enviadas por email o SMS (código 2FA, recuperación de contraseña, activación de cuenta) deben llegar al destinatario en menos de 60 segundos desde que el sistema las envía.

**Métrica**:
- Tiempo de entrega < 60 segundos (percentil 90)
- Email: < 60 segundos
- SMS: < 30 segundos
- Si no se entrega en 60 segundos: sistema reintenta automáticamente hasta 3 veces


**Aplica a**:
- RF-003 (Login con 2FA)
- RF-004 (Sistema de Notificaciones)
- RF-007 (Recuperación de contraseña)
- RF-022 (Notificaciones push de calendario)

**Estándar/Norma**: SLA de servicios de email/SMS (SendGrid, Twilio)

**Método de Verificación**:
- Pruebas con 100 envíos de email
- Pruebas con 50 envíos de SMS
- Registrar timestamp de envío desde sistema
- Registrar timestamp de recepción en bandeja
- Calcular diferencia y verificar p90 < 60 segundos

**Fuente**:
- Entrevista Oscar (código 2FA debe llegar rápido)
- RF-005 especifica <60 segundos
