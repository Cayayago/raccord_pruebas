# RNF-016 — Registro Completo de Auditoría

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-016 |
| Título | Registro Completo de Auditoría |
| Categoría | Seguridad / Trazabilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | RF-009 |

---

**Descripción**: El sistema debe registrar automáticamente todos los eventos de seguridad y acciones críticas en tabla LOG inmutable, reteniendo registros 90 días en sistema activo y 1 año en archivo.

**Métrica**:

- 100% de eventos críticos registrados
- Eventos incluyen:

        Logins (exitosos y fallidos)
        Visualizaciones de fotografías
        Visualizaciones de guiones
        Modificaciones de calendario
        Exportaciones de reportes
        Cambios de permisos
        Revocaciones de acceso
- Campos obligatorios por registro:

        Timestamp (precisión de milisegundos)
        Usuario
        Acción
        IP origen
        Dispositivo
        Resultado
- Logs inmutables (no editables ni eliminables)
- Retención: 90 días activo, 1 año archivo, purga automática a 15 meses


**Aplica a**:
- RF-009 (Log de auditoría)
- Todos los RF que ejecutan acciones críticas

**Estándar/Norma**:
- ISO/IEC 27001
- GDPR (retención y purga de datos personales)

**Método de Verificación**:
- Ejecutar 100 acciones críticas
- Verificar 100 registros en tabla LOG
- Intentar editar registro (debe fallar)
- Intentar eliminar registro (debe fallar)
- Verificar campos obligatorios presentes en todos los registros
