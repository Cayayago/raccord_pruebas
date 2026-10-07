# RNF-019 — Autenticación de Dos Factores Obligatoria

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-019 |
| Título | Autenticación de Dos Factores Obligatoria |
| Categoría | Seguridad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-003 |

---

**Descripción**: El sistema debe requerir autenticación de dos factores (2FA) mediante TOTP para el 100% de usuarios sin excepciones, garantizando segundo factor de autenticación más allá de contraseña.

**Métrica**:
- 100% de logins requieren 2FA
- Código TOTP de 6 dígitos
- Validez del código: 5 minutos
- Compatible con Google Authenticator, Authy, Microsoft Authenticator
- Sin opción de deshabilitar 2FA por usuario
- Bloqueo tras 3 intentos fallidos de código: 15 minutos


**Aplica a**: RF-003 (Login con 2FA)

**Estándar/Norma**:

- ISO/IEC 27001
- NIST SP 800-63B - Digital Identity Guidelines

**Método de Verificación**:

- Intentar login sin código 2FA (debe fallar)
- Verificar código generado por Google Authenticator funciona
- Verificar código expirado (>5 minutos) es rechazado
- Intentar 4 códigos incorrectos y verificar bloqueo
