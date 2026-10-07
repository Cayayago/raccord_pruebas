# RF-038 — Inventario de Recursos/Materiales

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-038 |
| Título | Inventario de Recursos/Materiales |
| Módulo | Funcionalidades Adicionales |
| Prioridad | Baja |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir a Coordinadores y Jefes de Departamento llevar inventario de materiales, recursos necesarios y listas de compras con estado de adquisición, SIN incluir gestión de presupuesto ni costos.


**Entradas**:

- Nombre del recurso/material (texto, máx 200 caracteres)
- Departamento responsable (selección única)
- Cantidad requerida (número entero)
- Descripción detallada (texto, máx 500 caracteres)
- Proveedor/Origen (texto, máx 200 caracteres, opcional)
- Fecha requerida (fecha)
- Estado de adquisición (selección única): Pendiente / En Proceso / Adquirido
- Escenas donde se requiere (selección múltiple, opcional)

**Proceso**:

-Validar que usuario sea Coordinador de Departamento, Jefe de Departamento o Administrador Total
- Mostrar formulario de registro de recurso
- Crear ítem en inventario vinculado a:

        Proyecto
        Departamento responsable
        Usuario que registró
- Permitir editar estado de adquisición:

        Pendiente → En Proceso (se está gestionando)
        En Proceso → Adquirido (ya está disponible)
- Mostrar vista de inventario por departamento:

        Tabla con: Recurso, Cantidad, Estado, Fecha requerida, Responsable
        Filtros: Por departamento, Por estado, Por fecha
        Indicadores visuales:

            Pendiente y fecha vencida (fecha requerida < hoy)
            Pendiente próximo a vencer (fecha requerida < 7 días)
            Adquirido




- Enviar notificaciones automáticas:

        7 días antes de fecha requerida: recordatorio a responsable
        Fecha vencida y estado Pendiente: alerta a coordinador

- Vincular recursos con escenas (RF-020) si se especificó
- Permitir exportar lista de compras pendientes en PDF o Excel (sin precios, solo ítems)

**Salidas**:

- Inventario de recursos por departamento
- Lista de compras pendientes
- Notificaciones de recordatorios
- Exportación en PDF/Excel

**Precondiciones**:

- Usuario debe ser Coordinador, Jefe de Departamento o Administrador Total
- Proyecto debe estar activo

**Postcondiciones**:

- Control de recursos necesarios para rodaje
- Identificación temprana de faltantes

**Actores**:

- Coordinadores de Departamento
- Jefes de Departamento
- Administrador Total

**Dependencias**:

- RF-020 (Vinculación con escenas)
- RF-022 (Notificaciones de recordatorios)
