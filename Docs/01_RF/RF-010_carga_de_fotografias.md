# RF-010 — Carga de Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-010 |
| Título | Carga de Fotografías |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-006, RNF-007, RNF-009, RNF-015, RNF-017, RNF-018, RNF-020, RNF-027 |

---

**Descripción**: El sistema debe permitir a usuarios autorizados (Script, Jefes de Departamento, Asistentes Onset) cargar fotografías de continuidad desde dispositivos móviles o tablets, completando campos de metadatos obligatorios en el momento de la subida.


**Entradas**:
- Archivo de fotografía (JPG/PNG máx 10 MB)
- Proyecto (selección de proyectos activos del usuario)
- Episodio (texto, máx 20 caracteres, opcional si no aplica)
- Número de Escena (número entero)
- Número de Toma (número entero)
- Personaje(s) (selección múltiple de personajes del proyecto)
- Tipo de Detalle (selección única): Vestuario / Maquillaje / Utilería / Set / Otro
- Estado de Continuidad (selección única): OK / Pendiente / Error a Corregir
- Comentarios adicionales (texto libre, máx 500 caracteres)

**Proceso**:
- Validar que usuario tenga permiso para subir fotografías (según RF-005)
- Validar formato de archivo (JPG/PNG)
- Validar tamaño de archivo (<10 MB)
- Si archivo >10 MB: comprimir automáticamente a 85% calidad manteniendo resolución
- Generar nomenclatura estandarizada automáticamente: "PROYECTO_EPISODIO_ESCENA_TOMA_PERSONAJE_DETALLE_VERSION"
- Si ya existe fotografía con misma nomenclatura: incrementar VERSION (V1 → V2)
- Aplicar marca de agua dinámica con: nombre usuario, timestamp, nombre
- Almacenar imagen original (sin marca de agua) en storage seguro (S3 o equivalente)
- Registrar acción en log de auditoría (RF-009)
- Si modo offline: almacenar localmente y sincronizar al reconectar

**Salidas**:

- Fotografía almacenada en storage con nomenclatura estandarizada
- Metadatos almacenados en base de datos
- Marca de agua aplicada para visualización
- Mensaje de confirmación al usuario
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe estar autenticado (RF-004)
- Usuario debe tener rol autorizado: Script, Jefe de Departamento, Asistente Onset
- Proyecto debe estar activo
- Personajes deben estar previamente registrados en el proyecto

**Postcondiciones**:

- Fotografía disponible inmediatamente para búsqueda (RF-012)
- Fotografía visible para usuarios autorizados según su rol

**Actores**:

- Script (Continuista)
- Jefe de Departamento (Vestuario, Maquillaje, Utilería, Fotografía, Arte)
- Asistente Onset

**Dependencias**:

- RF-003 (Autenticación)
- RF-005 (Sistema de roles y permisos)
- RF-009 (Log de auditoría)
