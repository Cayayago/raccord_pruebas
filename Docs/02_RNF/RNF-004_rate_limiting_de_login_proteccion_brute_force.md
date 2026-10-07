# RNF-004 — Rate Limiting de Login (Protección Brute Force)

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-004 |
| Título | Rate Limiting de Login (Protección Brute Force) |
| Categoría | Seguridad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-003 |

---

**Descripción**: El sistema debe implementar rate limiting en el endpoint de login para proteger contra ataques de fuerza bruta, limitando intentos fallidos por usuario y por IP.

**Métrica**:
- Máximo 5 intentos fallidos de login por cuenta en 15 minutos → Bloqueo temporal de cuenta (15 minutos)
- Máximo 20 intentos fallidos desde misma IP en 1 hora → Bloqueo temporal de IP (1 hora)
- Máximo 10 intentos fallidos en 24 horas → Bloqueo de cuenta requiriendo reset por administrador


**Aplica a**: RF-003 (Inicio de Sesión)

**Estándar/Norma**:

- OWASP Authentication Cheat Sheet
- ISO/IEC 27001 - Seguridad de la información

**Método de Verificación**:
- Pruebas automatizadas intentando 6 logins fallidos consecutivos
- Verificar que cuenta se bloquea tras 5to intento
- Verificar mensaje de error genérico (no revelar si email existe)
- Verificar bloqueo de IP tras 20 intentos

**Fuente**:
- Buenas prácticas de seguridad
- Protección contra ataques automatizados
