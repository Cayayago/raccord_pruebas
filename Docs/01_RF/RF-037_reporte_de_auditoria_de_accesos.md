# RF-037 — Reporte de Auditoría de Accesos

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-037 |
| Título | Reporte de Auditoría de Accesos |
| Módulo | Reportes y Analítica |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir al Productor de Línea generar reportes de auditoría de accesos y acciones con filtros personalizables para investigar actividad de usuarios y posibles filtraciones.


**Entradas**:
- Filtros de auditoría (opcionales, combinables):

        Usuario específico (selección única)
        Rango de fechas (desde-hasta)
        Tipo de acción (Login/Visualización fotografía/Visualización guion/Modificación calendario/Exportación reporte/Cambio de permisos/Revocación de acceso)
        Solo contenido sensible (checkbox: limita a visualizaciones de guiones y fotografías)
        Resultado (Éxito/Fallo)

**Proceso**:

- Validar que usuario sea Productor de Línea (Administrador Total) o Director
- Consultar tabla LOG de auditoría (RF-009) aplicando filtros seleccionados
- Ordenar resultados por timestamp descendente (más recientes primero)
- Para cada registro, mostrar:

        Timestamp (fecha y hora exacta con zona horaria)
        Usuario (nombre completo + email)
        Acción realizada (descripción clara)
        Detalles adicionales (ej: "Visualizó fotografía RACCORD_EP01_ESC005_T02_MARIA_VEST_V1.jpg")
        IP de origen
        Dispositivo (tipo, modelo, sistema operativo, navegador)
        Resultado (Éxito/Fallo)
- Implementar paginación (100 registros por página)
- Permitir exportar reporte completo en Excel con:

        Todas las columnas mencionadas
        Filtros aplicados en encabezado
        Fecha de generación del reporte
        Usuario que generó el reporte
- Registrar generación de reporte de auditoría en el mismo LOG (meta-auditoría)

**Salidas**:

- Lista de eventos de auditoría según filtros
- Exportación en Excel con todos los detalles
- Registro de generación de reporte en log

**Precondiciones**:
- Usuario debe ser Administrador Total o Director
- Debe existir al menos 1 registro en tabla LOG

**Postcondiciones**:

- Administrador puede identificar patrones de acceso sospechosos
- Investigación de posibles filtraciones con trazabilidad completa

**Actores**: Productor de Línea (Administrador Total) y Director

**Dependencias**:

- RF-009 (Log de auditoría debe estar registrando eventos)
