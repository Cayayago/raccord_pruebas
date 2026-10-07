# CU001 — Validar Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | CU001 |
| Título | Validar Usuario |
| Módulo | Módulo 1: Gestión de Usuarios y Seguridad |
| Actor primario | Cualquier usuario registrado |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Cualquier usuario registrado
- **Secundario:** Sistema de autenticación, Servicio de email/SMS, Sistema de LOG

#### Descripción

Verifica el acceso al sistema mediante correo electrónico, contraseña y código de autenticación de dos factores (2FA). Solo se permite el ingreso a usuarios activos vinculados a un proyecto específico. El sistema registra todos los intentos de acceso (exitosos y fallidos) en una tabla LOG mediante disparadores para auditoría de seguridad, incluyendo: timestamp, usuario, IP de origen, dispositivo y resultado del intento.

#### Precondiciones

- Usuario registrado en el sistema con estado "Activo"
- Usuario vinculado a al menos un proyecto activo
- Cuenta activada (si fue registrado por administrador)
- Servicio de 2FA operativo

#### Postcondiciones

**Si exitoso:**
- Token JWT generado (30min)
- Sesión activa creada
- Usuario redirigido según rol
- Registro en LOG

**Si fallido:**
- Contador de intentos +1
- Bloqueo temporal tras 3 intentos (15 min)
- Registro en LOG
- Mensaje de error genérico

#### Flujo Principal

1. Usuario ingresa email y contraseña
2. Sistema valida credenciales en BD
3. Sistema genera código 2FA de 6 dígitos
4. Sistema envía código al canal elegido (email/SMS)
5. Usuario ingresa código 2FA
6. Sistema valida código (válido 2 minutos)
7. Sistema genera token JWT (30 Min) y refresh token (7 días)
8. Sistema registra acceso en LOG
9. Sistema redirige a página principal según rol

#### Flujos Alternativos


**FA-001: Recuperación de Contraseña**: Usuario selecciona "¿Olvidaste tu contraseña?" → Sistema envía email con enlace temporal (1 hora) → Usuario crea nueva contraseña → Sistema actualiza y registra LOG

**FA-002: Reenvío Código 2FA** : Usuario no recibe código → Selecciona "Reenviar" → Sistema invalida anterior y envía nuevo por canal alternativo

**FA-003: Activación de Cuenta Pendiente** : Usuario con cuenta "Inactiva" intenta login → Sistema muestra mensaje → Opción "Reenviar email activación" → Usuario activa cuenta mediante enlace → Redirigido a login

#### Flujos Excepcionales

**FE-001: Cuenta Bloqueada (3 intentos fallidos)**: Sistema bloquea cuenta 15 minutos → Envía email notificación → Muestra mensaje bloqueo → Desbloqueo automático tras 15 min

**FE-002: Cuenta Revocada** : Usuario "Revocado" intenta login → Sistema detecta estado → Muestra mensaje "Contacta administrador" → No permite continuar

**FE-003: Servicio 2FA No Disponible** : Sistema detecta fallo 2FA → Activa modo degradado sin 2FA (JWT 30 min) → Alerta Admins → Obliga cambio contraseña en próximo login

**FE-004: Código 2FA Expirado** :Usuario ingresa código después de 2 minutos → Sistema rechaza → Muestra "Código expirado, solicita uno nuevo"

#### Frecuencia

Alta (5-10 logins/usuario/día)
