# RF-005 — Sistema de Roles y Permisos Granulares (RBAC)

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-005 |
| Título | Sistema de Roles y Permisos Granulares (RBAC) |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-001 |

---

**Descripción**: El sistema debe implementar control de acceso basado en roles (RBAC) con 4 roles predefinidos, cada uno con permisos granulares específicos sobre los 3 módulos principales (Continuidad Visual, Comunicación, Guiones).


**Entradas**:
- Rol asignado al usuario (definido en RF-005, RF-005)
- Acción solicitada por usuario (ej: subir fotografía, editar plan de rodaje, ver guion)
- Módulo al que intenta acceder (Continuidad Visual/plan de rodaje/Comunicación/Guiones)

**Proceso**:

- Usuario solicita ejecutar acción en el sistema
- Sistema consulta rol del usuario desde base de datos
- Sistema verifica en matriz de permisos si ese rol tiene permiso para esa acción en ese módulo
- Si permiso existe: permitir acción y ejecutar
- Si permiso NO existe: denegar acción y mostrar mensaje "No tiene permisos para realizar esta acción"
- Registrar intento de acceso (permitido o denegado) en log de auditoría
  
**Salidas**:

- Acción permitida o denegada
- Mensaje de error si acción denegada
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe estar autenticado (RF-003)
- Usuario debe tener rol asignado

**Postcondiciones** : Acción ejecutada si el permiso existe y registro de intento (exitoso o fallido) en log de auditoría

**Actores**: Todos los usuarios del sistema

**Dependencias**:

RF-003 (Usuario autenticado)

Nota Crítica: El sistema debe validar que siempre exista al menos 1 usuario con rol "Administrador Total" activo. No se puede eliminar o cambiar rol del último Administrador Total.
