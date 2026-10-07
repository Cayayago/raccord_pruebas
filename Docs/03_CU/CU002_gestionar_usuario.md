# CU002 — Gestionar Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | CU002 |
| Título | Gestionar Usuario |
| Módulo | Módulo 1: Gestión de Usuarios y Seguridad |
| Actor primario | Sub-admin |
| Frecuencia | Baja |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Sub-admin
- **Secundario:** Sistema de notificaciones, Sistema de LOG, Usuario creado

#### Descripción

Permite al Productor de Línea o Jefe de Producción realizar el registro, consulta, modificación, asignación de rol y revocación de acceso de usuarios. Los usuarios pueden actualizar su perfil personal (nombre, teléfono, foto de perfil, configuración de notificaciones) pero no pueden modificar su rol ni permisos. El sistema permite tres estados de usuario: Activo, Inactivo (suspensión temporal) y Revocado (finalización de contrato, sin posibilidad de reactivación por el usuario). Solo el administrador del proyecto puede reactivar usuarios inactivos.

#### Precondiciones

- Ejecutor con rol "Administrador Total" autenticado
- Al menos un proyecto activo en el sistema
- Para nuevo usuario: email único, cupo disponible
- No se puede revocar último Administrador Total

#### Postcondiciones

**Registro:**
- Usuario creado estado "Inactivo"
- Email de activación enviado
- Vinculado a proyecto
- Registro en LOG

**Modificación:**
- Campos actualizados
- Permisos recalculados si cambió rol
- Usuario notificado
- Registro en LOG

**Revocación:**
- Estado "Revocado"
- Sesiones cerradas (<60s)
- Tokens invalidados
- Eliminado de canales
- Registro en LOG

**Actualización perfil:**
- Campos editables actualizados
- Foto comprimida (500x500px)
- Sincronizado en todos dispositivos

#### Flujo Principal (Registro)

1. Administrador Total abre formulario "Nuevo Usuario"
2. Administrador completa datos: nombre, apellido, email, teléfono, departamento, rol, proyecto(s)
3. Sistema valida email único
4. Sistema genera contraseña temporal aleatoria
5. Sistema crea usuario con estado "Inactivo"
6. Sistema envía email con credenciales y enlace de activación
7. Sistema registra acción en LOG
8. Sistema muestra mensaje "Usuario creado exitosamente"

#### Flujo Principal (Modificación)

1. Administrador selecciona usuario de lista
2. Administrador modifica campos autorizados
3. Sistema valida cambios
4. Sistema actualiza registro en BD
5. Sistema recalcula permisos si cambió rol
6. Sistema notifica cambios al usuario
7. Sistema registra modificación en LOG

#### Flujo Principal (Revocación)

1. Administrador selecciona usuario y hace clic "Revocar Acceso"
2. Sistema muestra confirmación
3. Administrador confirma
4. Sistema cambia estado a "Revocado"
5. Sistema cierra todas las sesiones activas del usuario
6. Sistema invalida tokens JWT
7. Sistema registra revocación en LOG
8. Sistema envía email de notificación al usuario

#### Flujos Alternativos

**FA-001: Modificación Masiva de Roles** Admin selecciona múltiples usuarios → Cambia rol en grupo → Sistema recalcula permisos RBAC → Notifica usuarios afectados

**FA-002: Reactivación de Usuario Inactivo** : Admin selecciona usuario "Inactivo" → Clic "Reactivar" → Sistema cambia estado a "Activo" → Notifica usuario → Registra LOG

#### Flujos Excepcionales

**FE-001: Intento Revocar Último Admin** : Sistema detecta es último Admin Total → Rechaza operación → Muestra error "Debe haber al menos un Admin Total activo"

**FE-002: Email Duplicado en Registro** : Sistema detecta email ya existe → Rechaza registro → Sugiere "¿Olvidaste tu contraseña?" o usar email diferente

**FE-003: Enlace Activación Expirado** : Usuario intenta activar después de 48h → Sistema detecta expiración → Muestra mensaje → Admin debe reenviar enlace

#### Frecuencia

Baja
