# RF-004 — Sistema de Notificaciones por Email

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-004 |
| Título | Sistema de Notificaciones por Email |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-003 |

---

**Descripción**: El sistema debe proveer servicio de envío de notificaciones a usuarios mediante email para eventos críticos (activación de cuenta, código 2FA, recuperación de contraseña, cambios de calendario, comunicados oficiales).


**Entradas**:
- Destinatario (email o teléfono del usuario)
- Tipo de notificación (Activación/2FA/Recuperación/Cambio Calendario/Comunicado)
- Contenido del mensaje (texto dinámico según tipo)
- Prioridad (Normal/Urgente/Crítica)

**Proceso**:
- Validar destinatario (formato de email)
- Seleccionar plantilla según tipo de notificación
- Generar contenido dinámico (nombre usuario, código, enlace, etc.)
- Enviar mediante correo la notificación.


- Si envío falla: reintentar hasta 3 veces con delay exponencial (1s, 2s, 4s)
- Si 3 intentos fallan: registrar error en log y notificar a administradores
- Registrar envío exitoso en log de notificaciones

**Salidas**:

- Notificación enviada al destinatario
- Timestamp de envío registrado
- Confirmación de entrega (cuando servicio lo provea)
- Registro en log de notificaciones

**Precondiciones**: Usuario destinatario debe tener email o teléfono válido registrado y servicio de terceros, debe estar configurado y con créditos

**Postcondiciones**:

- Notificación entregada en menos de 60 segundos (RNF aplicable)
- Registro de entrega guardado para auditoría

**Actores**: Sistema (envío automático de mails) 

**Dependencias**:

- Integración con proveedor de email.
