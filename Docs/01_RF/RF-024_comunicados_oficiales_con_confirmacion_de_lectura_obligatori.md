# RF-024 — Comunicados Oficiales con Confirmación de Lectura Obligatoria

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-024 |
| Título | Comunicados Oficiales con Confirmación de Lectura Obligatoria |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | RNF-012 |

---

**Descripción**:El sistema debe permitir a Primera AD, Director y Productor de Línea enviar comunicados oficiales a todo el equipo o grupos específicos, requiriendo confirmación de lectura obligatoria y generando reporte de quiénes han leído.


**Entradas**:

- Destinatarios (selección única):

        Todo el equipo
        Todos los departamentos (excluye Talento)
        Solo departamentos creativos (Vestuario, Maquillaje, Utilería, Fotografía, Arte)
        Solo producción (Producción, Coordinadores)
- Asunto del comunicado (texto, máx 150 caracteres)
- Contenido del comunicado (texto enriquecido, máx 5000 caracteres)
- Documentos adjuntos (opcionales, PDF, máx 20 MB total)
- Requiere confirmación de lectura: Sí (por defecto) / No

**Proceso**:
- Validar que usuario sea Primera AD, Director o Productor de Línea
- Mostrar formulario de comunicado con editor de texto enriquecido (negrita, cursiva, listas, enlaces)
- Validar asunto y contenido completos
- Validar formato y tamaño de adjuntos
- Crear comunicado en base de datos con:

        Estado: Activo
        Timestamp de publicación
        Autor
        Destinatarios
- Publicar comunicado en Canal General con:

        Icono distintivo (megáfono o estrella)
        Fijado en parte superior del Canal General (sticky)
        Destacado visualmente (fondo color diferente)
- Enviar notificación push CRÍTICA a todos los destinatarios (sonido de alerta, vibración)
- Si requiere confirmación de lectura:

        Mostrar checkbox "He leído este comunicado" al final del mensaje
        Usuario debe marcar checkbox para confirmar lectura
        Sistema registra timestamp de confirmación
        Comunicado permanece fijado hasta que usuario confirme lectura
- Generar reporte automático para autor del comunicado:

        Lista de usuarios que confirmaron lectura (con timestamp)
        Lista de usuarios que NO han confirmado lectura
        Porcentaje de confirmaciones (ej: 45/50 usuarios - 90%)
- Permitir archivar comunicado (deja de estar fijado, pasa a historial)

**Salidas**:
- Comunicado publicado en Canal General
- Comunicado fijado en parte superior hasta confirmación de lectura
- Notificaciones push críticas enviadas
- Reporte de confirmaciones de lectura disponible para autor
- Registro en log de auditoría

**Precondiciones**: Usuario debe ser Primera AD, Director o Productor de Línea y el proyecto debe estar activo

**Postcondiciones**:
- Comunicado visible para todos los destinatarios
- Autor puede monitorear quiénes han leído
- Comunicado archivado queda en historial consultable

**Actores**:
- Primera Ayudante de Dirección
- Director
- Productor de Línea (Administrador Total)

**Dependencias**:

- RF-023 (Canal General debe existir)
- RF-022 (Notificaciones push)
- RF-009 (Log de auditoría)
