# RF-034 — Parte de Rodaje Diario Semi-Automático

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-034 |
| Título | Parte de Rodaje Diario Semi-Automático |
| Módulo | Reportes y Analítica |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir al Script generar el parte de rodaje diario de forma semi-automática, pre-completando información desde el calendario y fotografías del día, y permitiendo añadir datos manualmente.


**Entradas (pre-completadas automáticamente)**:

- Escenas rodadas (desde RF-018: eventos del calendario del día)
- Fotografías de continuidad tomadas (cuenta desde RF-010: fotografías con fecha = hoy)
- Estado de continuidad (resumen desde RF-014: X fotos OK, Y Pendientes, Z Errores)
- Cambios de calendario (desde RF-019: modificaciones realizadas durante el día)
- Mensajes urgentes (desde RF-023: mensajes con prioridad Urgente del día)
- Entradas (manuales, completadas por Script):

        Minutaje rodado (texto, ej: "12 minutos")
        Incidencias técnicas (texto libre, máx 500 caracteres)
        Notas generales de producción (texto libre, máx 1000 caracteres)
        Observaciones para día siguiente (texto libre, máx 500 caracteres)

**Proceso**:

- Validar que usuario sea Script
- Al final de jornada de rodaje, Script abre "Generar Parte de Rodaje"
- Sistema pre-completa automáticamente:

        Fecha del parte
        Proyecto
        Escenas programadas para hoy (desde calendario)
        Escenas efectivamente rodadas (Script marca cuáles se completaron)
        Total de fotografías de continuidad subidas hoy
        Resumen de estados: X OK, Y Pendientes, Z Errores
        Cambios de calendario realizados hoy (lista cronológica)
        Mensajes urgentes enviados/recibidos


- Script completa campos manuales:

        Minutaje rodado
        Incidencias técnicas (ej: "Falla de cámara B en toma 15, reemplazo en 30 min")
        Notas generales
        Observaciones para mañana


- Generar PDF con formato estándar de parte de rodaje:

        Encabezado con proyecto, fecha, Script responsable
        Sección 1: Escenas rodadas
        Sección 2: Fotografías y continuidad
        Sección 3: Cambios y novedades
        Sección 4: Incidencias técnicas
        Sección 5: Notas de producción
        Sección 6: Observaciones para día siguiente
        Firma digital del Script


- Aplicar marca de agua
- Enviar automáticamente por email a: Productor de Línea, Director, Primera AD
- Almacenar PDF en storage vinculado al proyecto

**Salidas**:

- Parte de rodaje diario en PDF
- Email automático enviado a destinatarios
- PDF almacenado en historial de partes de rodaje
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe ser Script
- Debe haber actividad de rodaje en el día (eventos en calendario, fotografías subidas)

**Postcondiciones**:

- Parte de rodaje disponible para consulta histórica
- Productor y Director reciben reporte automático diario

**Actores**: Script (Continuista) - genera el parte

**Dependencias**:
- RF-010 (Fotografías del día)
- RF-018 (Eventos del calendario)
- RF-019 (Cambios de calendario)
- RF-014 (Estados de continuidad)
- RF-023 (Mensajes urgentes)
- Sistema de notificaciones por email (RF-004)
