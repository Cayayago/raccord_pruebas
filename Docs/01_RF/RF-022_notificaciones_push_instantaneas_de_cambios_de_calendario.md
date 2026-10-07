# RF-022 — Notificaciones Push Instantáneas de Cambios de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-022 |
| Título | Notificaciones Push Instantáneas de Cambios de Calendario |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-003, RNF-011, RNF-012 |

---

**Descripción**: El sistema debe enviar notificaciones push automáticas en menos de 30 segundos a todos los usuarios afectados cuando se crea, modifica o cancela un evento en el calendario.


**Entradas (capturadas automáticamente)**:

- Evento de calendario modificado/creado/cancelado (desde RF-018 o RF-019)
- Tipo de cambio: Creación / Modificación / Cancelación
- Campos que cambiaron (en caso de modificación)
- Prioridad asignada: Normal / Urgente / Crítico
- Lista de usuarios afectados (calculada automáticamente)

**Proceso**:
- Cuando se crea/modifica/cancela evento: trigger automático ejecuta envío de notificaciones
- Sistema identifica usuarios afectados:

        Todos los usuarios cuyos personajes están involucrados en las escenas del evento
        Jefes de departamentos mencionados en el evento
        Script siempre incluido
        Primera AD siempre incluida
- Generar contenido de notificación:

        Título: "Cambio en calendario: [Fecha]"
        Descripción: Resumen de qué cambió (ej: "Locación cambió de 'Estudio A' a 'Locación Externa - Parque Nacional'")
        Detalles completos: Todos los campos del evento
        Quién realizó el cambio
        Timestamp del cambio
        Enlace directo al evento en calendario

- Enviar notificación mediante Firebase Cloud Messaging (FCM):

        Push a app móvil (iOS/Android) con alerta sonora y badge
        Si app está abierta: mostrar banner in-app
        Si app está cerrada: notificación en centro de notificaciones del dispositivo


- Aplicar prioridad visual:

        Normal: icono estándar, sonido suave
        Urgente: icono naranja, sonido distintivo, vibración corta
        Crítico: icono rojo, sonido de alerta, vibración larga

- Registrar timestamp de envío de notificación
- Registrar timestamp de lectura cuando usuario abre notificación
- Si usuario tiene preferencia de email activada: enviar también por email (no reemplaza push)
- Si notificación no se entrega en 30 segundos: reintentar hasta 3 veces
- Si 3 reintentos fallan: registrar error y notificar a administradores

**Salidas**:
- Notificación push entregada en <30 segundos
- Registro de envío y lectura en base de datos
- Email enviado (si usuario tiene preferencia activada)
- Registro de errores de entrega (si aplica)

**Precondiciones**:
- Evento debe existir en calendario (RF-018)
- Usuarios afectados deben tener dispositivos registrados para push notifications
- Firebase Cloud Messaging debe estar configurado

**Postcondiciones**:
- Usuarios notificados en menos de 30 segundos (Objetivo Específico 3)
- Confirmaciones de lectura registradas para seguimiento

**Actores**:
- Sistema (envío automático)
- Servicio de terceros (Firebase Cloud Messaging)

**Dependencias**:

- RF-018 (Creación de eventos)
- RF-019 (Modificación de eventos)
- Integración con Firebase Cloud Messaging
