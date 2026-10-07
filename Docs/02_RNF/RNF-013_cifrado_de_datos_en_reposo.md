# RNF-013 — Cifrado de Datos en Reposo

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-013 |
| Título | Cifrado de Datos en Reposo |
| Categoría | Seguridad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe cifrar toda la información sensible almacenada usando AES-256, incluyendo fotografías, guiones, datos personales y contraseñas (estas últimas adicionalmente hasheadas con bcrypt).

**Métrica**:
- 100% de fotografías cifradas con AES-256
- 100% de guiones cifrados con AES-256
- 100% de datos personales cifrados
- Contraseñas hasheadas con bcrypt (12 rounds) + almacenadas en campo cifrado
- Claves de cifrado rotadas cada 90 días


**Aplica a**:
- Almacenamiento (S3 o equivalente)
- Base de datos PostgreSQL
- Todos los RF que manejan información sensible

**Estándar/Norma**:
- ISO/IEC 27001 - Seguridad de la información
- NIST SP 800-175B - Guideline for Using Cryptographic Standards

**Método de Verificación**:
- Auditoría de seguridad automatizada con herramientas (OWASP ZAP, Nessus)
- Verificar configuración de cifrado en S3 (server-side encryption)
- Verificar cifrado de columnas sensibles en PostgreSQL
- Intentar acceder a archivos directamente desde storage (deben estar cifrados)

**Fuente**:
- Entrevista Oscar (seguridad extrema, caso Netflix)
- Objetivo de proteger información confidencial
