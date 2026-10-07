# RF-017 — Creación de Proyectos

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-017 |
| Título | Creación de Proyectos |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir a Administradores Totales crear proyectos nuevos con información básica que servirá como contenedor para todas las fotografías, guiones y desglose y plan de rodaje de esa producción específica.


**Entradas**:

- Nombre del proyecto (texto, máx 100 caracteres)
- Tipo de producción (Película/Serie/Cortometraje/Comercial/Documental/Video Institucional)
- Fecha de inicio estimada (fecha)
- Fecha de finalización estimada (fecha)
- Descripción breve (texto, máx 500 caracteres, opcional)

**Proceso**:

- Validar que usuario sea Administrador Total
- Validar que nombre de proyecto no esté duplicado
- Crear registro de proyecto en base de datos con estado "Activo"
- Generar ID único de proyecto
- Crear automáticamente estructuras base:

- Asignar creador como Administrador Total del proyecto
- Registrar creación en log de auditoría

**Salidas**:

- Proyecto creado en base de datos
- Estructura de directorios en storage
- Calendario inicializado
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe ser Administrador Total
- Usuario debe estar autenticado

**Postcondiciones**:

- Proyecto disponible para asignación a usuarios (RF-003)
- Proyecto visible en selector de proyectos de todos los módulos

**Actores**: Administrador Total (Productor de Línea)

**Dependencias**: RF-001 o RF-002 (Administrador Total debe existir)
