# RF-014 — Gestión de Estados de Continuidad

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-014 |
| Título | Gestión de Estados de Continuidad |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir al Script marcar cada fotografía con uno de tres estados de continuidad (OK, Pendiente, Corregir) y enviar notificaciones automáticas al departamento correspondiente cuando se marca un error.


**Entradas**:

- Fotografía seleccionada
- Estado a asignar: OK / Pendiente / Error a Corregir
- Descripción del error (texto, máx 300 caracteres, obligatorio si Estado = Error)

**Proceso**:

- Validar que usuario sea Script (solo Script puede cambiar estados)
- Mostrar dropdown con 3 estados disponibles
- Si usuario selecciona "Error a Corregir":
- Mostrar campo obligatorio "Descripción del error"

        Identificar departamento correspondiente según Tipo de Detalle de la fotografía:

            Si Detalle = Vestuario → notificar a Jefe de Vestuario
            Si Detalle = Maquillaje → notificar a Jefe de Maquillaje
            Si Detalle = Utilería → notificar a Jefe de Utilería
            Si Detalle = Set → notificar a Jefe de Arte

        Enviar notificación push inmediata al Jefe de Departamento con:

            Thumbnail de la fotografía
            Descripción del error
            Enlace directo a la fotografía
            Prioridad: Urgente

- Actualizar estado de fotografía en base de datos
- Registrar cambio de estado en log de auditoría
- Si estado cambia de "Error" a "OK": enviar notificación de confirmación al departamento

**Salidas**:

- Estado de fotografía actualizado en base de datos
- Notificación push enviada a Jefe de Departamento (si aplica)
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe ser Script
- Fotografía debe existir en sistema

**Postcondiciones**: Estado visible en búsqueda y visualización de fotografía


**Actores**: Script (Continuista) - único autorizado para cambiar estados

**Dependencias**:

- RF-010 (Fotografías deben existir)
- RF-009 (Log de auditoría)
