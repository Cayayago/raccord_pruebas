# RF-006 — Política de Contraseñas Seguras

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-006 |
| Título | Política de Contraseñas Seguras |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | RNF-005, RNF-017 |

---

**Descripción**: El sistema debe validar y enforcar una política de contraseñas seguras para todos los usuarios en registro inicial, cambio de contraseña y recuperación de contraseña.


**Entradas**:
- Contraseña propuesta por usuario (texto)
- Confirmación de contraseña (texto)
- Contraseñas anteriores del usuario (últimas 3, hasheadas en BD)

**Proceso**:

- Validar longitud mínima: 12 caracteres
- Validar presencia de al menos 1 letra mayúscula (A-Z)
- Validar presencia de al menos 1 letra minúscula (a-z)
- Validar presencia de al menos 1 número (0-9)
- Validar presencia de al menos 1 carácter especial (!@#$%^&*()_+-=[]{}|;:,.<>?)
- Validar que contraseña y confirmación coincidan
- Validar que contraseña NO sea igual a las últimas 3 contraseñas del usuario (comparar hashes)
- Si todas validaciones pasan: hashear con bcrypt (12 rounds) y almacenar
- Si alguna validación falla: mostrar mensaje específico del error

**Salidas**:

- Contraseña hasheada y almacenada en base de datos
- Mensaje de confirmación o error específico al usuario
- Registro en log de cambio de contraseña (no almacena contraseña, solo evento)

**Precondiciones**: Usuario debe estar en proceso de registro (RF-006, RF-006) o cambio de contraseña (RF-006)

**Postcondiciones**:

- Contraseña almacenada de forma segura (hasheada)
- Historial de contraseñas actualizado (últimas 3)

**Actores**: Todos los usuarios del sistema

**Dependencias**:

Ninguna (política aplicable en múltiples RF)
