# CU011 — Gestionar Comunicados Generales

## Identificación

| Campo | Valor |
|---|---|
| ID | CU011 |
| Título | Gestionar Comunicados Generales |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Administrador |
| Frecuencia | Baja |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador
- **Secundario:** Sistema Canal General, Sistema notificaciones, Sistema reportes, Sistema LOG

#### Descripción

Permite a la Primera AD, Director y Productor de Línea enviar comunicados oficiales a todo el equipo o grupos específicos. Los comunicados se destacan visualmente en la app con icono especial y permanecen fijados en la parte superior del Canal General hasta ser archivados. Los comunicados requieren confirmación de lectura obligatoria (checkbox) y el sistema genera reporte de quién ha leído el comunicado.

#### Precondiciones

- Ejecutor Primera AD/Director/Productor autenticado
- Proyecto activo, destinatarios estado "Activo"

#### Postcondiciones

**Creación:**
- Destinatarios seleccionados (todos/deptos/creativos/producción/talento)
- Formulario completado (asunto 150 chars, contenido 5000 chars HTML, PDF ≤20MB)
- Comunicado en BD
- Publicado Canal General (icono, fijado sticky, fondo destacado)
- Notificación crítica a destinatarios
- Si requiere confirmación: checkbox "He leído" mostrado, permanece fijado hasta confirmar
- Registro en LOG

**Usuario lee:**
- Checkbox marcado
- Timestamp guardado
- Deja de estar fijado para usuario
- Notificación a autor

**Reporte confirmaciones:**
- Modal con leídos (lista + timestamp)
- No leídos (lista+tiempo transcurrido)
- Estadísticas (total/confirmados/%/pendientes)
- Opción reenviar recordatorio
- Exportable PDF/Excel

**Archivo:**
- Solo autor puede
- Deja de estar fijado
- Movido a "Archivados"
- Estado "Archivado"
- Registro en LOG

#### Flujo Principal

1. Primera AD/Director/Productor hace clic "Nuevo Comunicado"
2. Sistema muestra formulario con editor de texto enriquecido
3. Usuario selecciona destinatarios: Todos/Deptos/Creativos/Producción/Talento
4. Usuario completa: Asunto (150 chars), Contenido (5000 chars HTML), Adjuntos PDF (≤20MB)
5. Usuario marca "Requiere confirmación de lectura" (checkbox por defecto activo)
6. Usuario hace clic "Publicar"
7. Sistema crea comunicado en BD
8. Sistema publica en Canal General con icono 📣 y fondo destacado
9. Sistema fija comunicado en parte superior (sticky)
10. Sistema envía notificación push CRÍTICA a todos los destinatarios
11. Usuario destinatario abre comunicado
12. Si requiere confirmación: sistema muestra checkbox "He leído este comunicado"
13. Usuario marca checkbox
14. Sistema registra timestamp de confirmación
15. Comunicado deja de estar fijado para ese usuario

#### Flujos Alternativos

**FA-001: Programar Comunicado Futuro** : Autor programa fecha/hora publicación → Sistema guarda en cola → Publica automáticamente en horario → Envía notificaciones

#### Flujos Excepcionales

**FE-001: Reenvío Recordatorio a No Leídos** : Autor ve reporte → Detecta usuarios sin leer tras 24h → "Reenviar Recordatorio" → Sistema envía notificación urgente solo a pendientes

#### Frecuencia

Baja
