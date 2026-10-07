# CU008 — Notificar Cambios de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | CU008 |
| Título | Notificar Cambios de Calendario |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Todos los usuarios. |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos los usuarios.
- **Secundario:** Firebase Cloud Messaging, SendGrid, Usuarios afectados

#### Descripción

El sistema envía automáticamente notificaciones push instantáneas (<30 segundos) a todos los usuarios afectados cuando se modifica, crea o cancela un evento en el calendario. La notificación identifica claramente: qué cambió, quién realizó el cambio, y cuándo. Los usuarios reciben notificación en la app móvil con alerta sonora y badge, y opcionalmente por email (configurable por usuario). La Primera AD puede marcar cambios como "Urgente" o "Crítico" para destacarlos visualmente. El sistema registra confirmación de lectura (timestamp) por cada usuario.

#### Precondiciones

- Evento creado/modificado/cancelado (trigger desde CU007)
- Usuarios con FCM tokens válidos
- Firebase y SendGrid operativos
- Permisos notificaciones concedidos en dispositivos

#### Postcondiciones

**Envío exitoso:**
- Trigger automático
- Usuarios afectados identificados
- Contenido generado (título+descripción+detalles+autor+timestamp+deep link)
- Prioridad aplicada (Normal/Urgente/Crítico con iconos/sonidos/vibraciones diferenciados)
- Enviado vía FCM (<30s)
- Email adicional si preferencia activa
- Reintentos automáticos (3×) si falla
- Timestamp envío en BD

**Usuario abre:**
- Timestamp lectura registrado
- Badge -1
- App redirige a evento
- Estado "Leída"

**Comunicados obligatorios:**
- Checkbox "He leído" requerido
- Timestamp confirmación guardado
- Reporte disponible (leídos/pendientes/%)

#### Flujo Principal

1. Sistema detecta cambio en tabla CALENDARIO (trigger automático)
2. Sistema identifica usuarios afectados
3. Sistema genera contenido de notificación: título + descripción + detalles + autor + timestamp
4. Sistema aplica prioridad visual según criticidad (Normal/Urgente/Crítico)
5. Sistema envía notificación vía Firebase Cloud Messaging
6. Si usuario tiene preferencia email activa: sistema envía email adicional
7. Sistema registra timestamp de envío en BD
8. Usuario recibe notificación push en dispositivo (<30 segundos)
9. Usuario abre notificación
10. Sistema registra timestamp de lectura
11. App redirige a evento en calendario

#### Flujos Alternativos

**FA-001: Notificación con Retraso Programado** : Primera AD programa notificación para envío futuro (ej: 24h antes de rodaje) → Sistema guarda en cola programada → Envía en horario especificado

#### Flujos Excepcionales

**FE-001: Firebase No Disponible** : Sistema detecta FCM caído → Guarda notificaciones en cola → Envía emails alternativos → Reintenta FCM cada 5min → Alerta técnicos

**FE-002: Usuario Sin Token FCM** : Sistema no encuentra token válido → Envía solo email → Registra usuario sin token → Sugiere reactivar notificaciones push

**FE-003: Envío Masivo (>100 usuarios)** : Sistema detecta >100 destinatarios → Divide en lotes de 100 → Procesa en paralelo → Evita rate limit FCM

#### Frecuencia

Alta
