# RF-007 — Recuperación de Contraseña

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-007 |
| Título | Recuperación de Contraseña |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | RNF-003, RNF-005, RNF-017 |

---

**Descripción**: El sistema debe permitir a usuarios que olvidaron su contraseña solicitar un restablecimiento mediante enlace de recuperación enviado a su email registrado.


**Entradas**:
- Email del usuario registrado
- Nueva contraseña (en formulario tras clic en enlace)
- Confirmación de nueva contraseña

**Proceso**:
- Validar que email exista en base de datos
- Enviar email con enlace de recuperación.
- Usuario hace clic en enlace
- Usuario ingresa nueva contraseña (2 veces para confirmación)
- Aplicar validaciones de RF-006 (Política de contraseñas)
- Validar que nueva contraseña NO sea igual a las últimas 3
- Hashear nueva contraseña con bcrypt (12 rounds)
- Actualizar contraseña en base de datos
- Cerrar todas las sesiones activas del usuario
- Enviar email de confirmación de cambio exitoso

**Salidas**:

- Email con enlace de recuperación enviado
- Contraseña actualizada en base de datos
- Todas las sesiones activas del usuario cerradas
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe estar registrado en el sistema
- Email del usuario debe ser válido y accesible

**Postcondiciones**:

- Contraseña antigua queda invalidada
- Usuario debe iniciar sesión nuevamente con nueva contraseña
- Enlace de recuperación queda invalidado (no reutilizable)

**Actores**: Cualquier usuario registrado que olvidó su contraseña

**Dependencias**:

- RF-004 (Sistema de notificaciones por email)
- RF-006 (Política de contraseñas seguras)
