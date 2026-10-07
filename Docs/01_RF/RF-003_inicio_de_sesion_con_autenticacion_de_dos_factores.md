# RF-003 — Inicio de Sesión con Autenticación de Dos Factores

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-003 |
| Título | Inicio de Sesión con Autenticación de Dos Factores |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Crítica |
| Estado | Completado  |
| RNF asociados | RNF-001, RNF-002, RNF-003, RNF-004, RNF-005, RNF-017, RNF-019 |

---

**Descripción**: El sistema debe permitir a usuarios registrados iniciar sesión validando credenciales (email + contraseña) y requiriendo posteriormente autenticación de dos factores (2FA) mediante código TOTP de 6 dígitos enviado al canal elegido por el usuario.


**Entradas**:
- Email del usuario
- Contraseña
- Código 2FA de 6 dígitos
- Canal preferido para 2FA (Email)

**Proceso**:
- Validar email y contraseña contra base de datos
- Si las credenciales son incorrectas: registrar intento fallido y mostrar error genérico ("Email o contraseña incorrectos")
- Si 3 intentos fallidos consecutivos: bloquear cuenta temporalmente (15 minutos)
- Enviar código al canal seleccionado por usuario
- Validar código ingresado (válido por 5 minutos)
- Si código es incorrecto 3 veces: bloquear cuenta temporalmente (15 minutos)
- Registrar acceso exitoso en log de auditoría (timestamp, IP origen, dispositivo, resultado)

**Salidas**:
- Redirección a página principal según rol del usuario
- Registro en log de auditoría: timestamp, IP origen, dispositivo, resultado

**Precondiciones**:
- Usuario debe estar registrado en el sistema (RF-001, o RF-002)
- Usuario debe estar en estado "Activo"
- Usuario debe haber activado su cuenta (si fue registrado por RF-002)

**Postcondiciones**:

- Usuario puede acceder a módulos según su rol
- Registro de acceso exitoso en tabla LOG de auditoría

**Actores**: Todos los usuarios registrados del sistema

Dependencias:

RF-001 o RF-002 (Usuario debe estar registrado)
