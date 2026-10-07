# RF-021 — Notas Personales Privadas en Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-021 |
| Título | Notas Personales Privadas en Calendario |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Baja |
| Estado | Pendiente |
| RNF asociados | RNF-027, RNF-033 |

---

**Descripción**: El sistema debe permitir a cualquier usuario crear notas personales privadas asociadas a cualquier día del calendario que sean completamente privadas y no visibles para otros usuarios ni administradores.


**Entradas**:

- Fecha seleccionada en calendario
- Contenido de nota personal (texto libre, máx 1000 caracteres)
- Tipo de nota (opcional): Recordatorio / Tarea pendiente / Observación / Idea

**Proceso**:
- Validar que usuario esté autenticado
- Crear nota en base de datos con:

        ID de usuario (propietario)
        Fecha asociada
        Contenido
        Tipo (opcional)
        Timestamp de creación
        Flag "privada" = true

- Nota se almacena con cifrado adicional (solo usuario puede descifrarla)
- Mostrar icono de candado en calendario solo visible para su creador en la fecha correspondiente
- Permitir editar y eliminar nota (solo el propietario)
- Permitir búsqueda de notas personales por fecha o contenido (solo el propietario)
- Notas NO se incluyen en:

        Reportes de producción (RF-032 a RF-037)
        Auditorías de acceso (RF-009)
        Exportaciones de calendario

**Salidas**:

- Nota personal almacenada cifrada en base de datos
- Icono de candado visible solo para creador en calendario
- Nota excluida de reportes y auditorías

**Precondiciones**:
- Usuario debe estar autenticado
- Fecha debe ser parte del calendario del proyecto activo

**Postcondiciones**:
- Nota accesible solo por su creador
- Privacidad absoluta garantizada (ni administradores pueden ver contenido)

**Actores**: Cualquier usuario del sistema

**Dependencias**:

- RF-003 (Usuario autenticado)
- RF-018 (Calendario debe existir)
