# RF-019 — Modificación de Eventos de Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-019 |
| Título | Modificación de Eventos de Calendario |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-010, RNF-011 |

---

**Descripción**: El sistema debe permitir a Primera AD y Administrador Total modificar eventos existentes en el calendario, registrando qué cambió y notificando automáticamente a usuarios afectados.


**Entradas**:

- Evento seleccionado
- Campos a modificar (cualquiera de los 12 campos de RF-018)
- Prioridad del cambio (Normal / Urgente / Crítico)

Proceso:

- Validar que usuario sea Primera AD o Administrador Total
- Mostrar formulario con datos actuales pre-cargados
- Usuario modifica campos necesarios
- Sistema detecta automáticamente qué campos cambiaron (comparación pre/post)
- Si cambio es en: Fecha, Escenas, Locación, Personajes → considerar cambio crítico automáticamente
- Usuario puede marcar cambio como "Urgente" o "Crítico" manualmente
- Actualizar evento en base de datos
- Registrar cambio en tabla de historial de calendario:

        Qué campos cambiaron
        Valor anterior vs valor nuevo
        Quién modificó
        Timestamp


- Recalcular usuarios afectados (pueden cambiar si se añaden/quitan personajes)
- Enviar notificaciones push (RF-022) con nivel de prioridad:

        Normal: notificación estándar
        Urgente: notificación con color naranja y sonido distintivo
        Crítico: notificación con color rojo, sonido de alerta y vibración

**Salidas**:

- Evento actualizado en calendario
- Historial de cambios registrado
- Notificaciones push enviadas según prioridad
- Registro en log de auditoría

**Precondiciones**:
- Usuario debe ser Primera AD o Administrador Total
- Evento debe existir en calendario

**Postcondiciones**:
- Cambios visibles inmediatamente en calendario
- Usuarios afectados notificados en <30 segundos (Objetivo Específico 3)

**Actores**:
- Primera Ayudante de Dirección
- Administrador Total

**Dependencias**:
- RF-018 (Evento debe existir)
- RF-009 (Log de auditoría)
