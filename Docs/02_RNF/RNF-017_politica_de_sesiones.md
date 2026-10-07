# RNF-017 — Política de Sesiones

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-017 |
| Título | Política de Sesiones |
| Categoría | Seguridad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | RF-003, RF-006, RF-007, RF-010 |

---

**Descripción**: El sistema debe gestionar sesiones de usuario con tokens JWT de corta duración, renovación automática con refresh tokens y cierre forzado de sesiones al cambiar contraseña o revocar acceso.

**Métrica**:
- Access token (JWT): validez de 2 horas
- Refresh token: validez de 7 días
- Renovación automática de access token antes de expiración (sin requerir re-login)
- Cierre forzado de todas las sesiones en:

        Cambio de contraseña
        Revocación de acceso
        Cambio de rol
- Sesiones cerradas en <60 segundos tras evento de cierre forzado


**Aplica a**:
- RF-003 (Login)
- RF-007 (Recuperación de contraseña)
- RF-010 (Revocación de acceso - mencionado en RF-006 sobre gestión de usuarios)

**Estándar/Norma**:

- ISO/IEC 27001
- OWASP Session Management Cheat Sheet

**Método de Verificación**:
- Iniciar sesión y verificar token JWT válido por 2 horas
- Esperar expiración y verificar renovación automática con refresh token
- Cambiar contraseña de usuario con 3 sesiones activas
- Verificar 3 sesiones cerradas en <60 segundos
