# RNF-014 — Cifrado de Datos en Tránsito

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-014 |
| Título | Cifrado de Datos en Tránsito |
| Categoría | Seguridad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe usar TLS 1.3 para todas las comunicaciones entre cliente y servidor, con certificados SSL válidos y renovación automática.

**Métrica**:
- 100% de comunicaciones sobre HTTPS
- TLS versión ≥ 1.3
- Certificado SSL válido (no auto-firmado en producción)
- Renovación automática de certificados antes de expiración (Let's Encrypt o similar)
- Redirección automática de HTTP a HTTPS


**Aplica a**:
- Todas las comunicaciones API (REST)
- Aplicación Flutter (iOS, Android, Windows, macOS) y página web de ingreso
- Comunicación con servicios de terceros (S3, Firebase, etc.)

**Estándar/Norma**:
- ISO/IEC 27001
- PCI DSS (si aplica para pagos futuros)

**Método de Verificación**:

- Verificar calificación A o A+
- Verificar TLS 1.3 habilitado
- Intentar conexión HTTP sin S (debe redirigir a HTTPS)
