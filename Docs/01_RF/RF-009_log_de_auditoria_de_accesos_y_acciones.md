# RF-009 — Log de Auditoría de Accesos y Acciones

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-009 |
| Título | Log de Auditoría de Accesos y Acciones |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | RNF-016 |

---

**Descripción**: El sistema debe registrar automáticamente en una tabla LOG todos los eventos de seguridad y acciones críticas realizadas por usuarios para garantizar trazabilidad completa.


**Entradas (capturadas automáticamente por el sistema)**:

- Usuario que ejecuta acción (ID y email)
- Tipo de acción (Login exitoso/fallido, Visualización de fotografía, Visualización de guion, Modificación de calendario, Exportación de reporte, Cambio de permisos, Revocación de acceso)
- Timestamp (fecha y hora exacta con zona horaria)
- IP de origen
- Dispositivo (tipo, modelo, sistema operativo, navegador)
- Resultado (Éxito/Fallo)
- Detalles adicionales (ej: qué fotografía visualizó, qué evento del calendario modificó)

**Proceso**:

- Cada acción crítica del sistema ejecuta trigger que registra evento en tabla LOG
- Sistema captura automáticamente contexto de la acción (usuario, IP, dispositivo)
- Registro se almacena en tabla LOG de base de datos
- Sistema NO permite edición ni eliminación de registros de log (solo inserción)
- Logs se retienen 90 días en sistema activo (acceso inmediato)
- Logs mayores a 90 días se archivan automáticamente (acceso mediante solicitud)
- Logs mayores a 15 meses se purgan automáticamente

**Salidas**:
- Registro insertado en tabla LOG con todos los campos
- Registro inmutable (no puede editarse ni eliminarse)

**Precondiciones**: Usuario debe ejecutar alguna acción en el sistema

**Postcondiciones**:

- Evento queda registrado permanentemente en log

**Actores**:

- Sistema (registro automático)
- Todos los usuarios del sistema (generan eventos)

**Dependencias**: Base de datos PostgreSQL con tabla LOG configurada

Eventos Registrados:

- Intentos de login (exitosos y fallidos)
- Visualización de fotografías de continuidad
- Visualización de guiones
- Subida de fotografías
- Exportación de reportes
- Cambios de roles/permisos
- Revocación de accesos
- Cambios de contraseña
