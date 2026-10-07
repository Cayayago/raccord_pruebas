# CU003 — Gestionar Roles y Permisos

## Identificación

| Campo | Valor |
|---|---|
| ID | CU003 |
| Título | Gestionar Roles y Permisos |
| Módulo | Módulo 1: Gestión de Usuarios y Seguridad |
| Actor primario | Administrador total, sub-admi |
| Frecuencia | Baja |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador total, sub-admi
- **Secundario:** Sistema RBAC, Sistema de LOG, Usuario afectado

#### Descripción

Permite al Productor de Línea asignar y modificar roles de usuario entre los 7 niveles disponibles: Administrador Total, Continuidad Total, Jefe de Departamento, Asistente de Departamento, Dirección, Talento, y Lectura General. Cada rol tiene permisos granulares predefinidos sobre los módulos de Continuidad Visual, Calendario, Comunicación y Seguridad. El sistema valida que al menos un usuario tenga rol de Administrador Total en todo momento.

#### Precondiciones

- Ejecutor con rol "Administrador Total" autenticado
- Usuario objetivo existe con estado "Activo" o "Inactivo"
- Existe al menos 1 Administrador Total adicional (si se va a cambiar último Admin)

#### Postcondiciones

**Si exitoso:**
- Rol actualizado
- Permisos recalculados según matriz RBAC
- Cache invalidado (<2s)
- Usuario notificado
- Registro en LOG

**Si intento cambiar último Admin:**
- Operación rechazada
- Mensaje de error
- Registro en LOG
- Sin cambios en BD

#### Flujo Principal

1. Administrador Total selecciona usuario de lista
2. Administrador hace clic "Cambiar Rol"
3. Administrador selecciona nuevo rol
4. Sistema valida que no es el último Administrador Total
5. Sistema actualiza rol en BD
6. Sistema recalcula permisos según matriz RBAC
7. Sistema invalida cache de permisos (<2s)
8. Sistema notifica cambio al usuario (email + push)
10. Sistema registra cambio en LOG

#### Flujos Alternativos

**FA-001: Asignación Temporal de Permisos Elevados** : Admin otorga rol superior temporal (ej: Asistente → Jefe Depto por 48h) → Sistema programa reversión automática → Notifica usuario → Al cumplir plazo revierte rol y notifica

#### Flujos Excepcionales

**FE-001: Cambio Rol Último Admin Total** : Sistema detecta es último Admin → Bloquea operación → Error "Asigna otro Admin Total primero"

#### Frecuencia

Baja
