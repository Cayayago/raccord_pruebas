# RF-001 — Auto-registro del Primer Usuario (Administrador Total)

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-001 |
| Título | Auto-registro del Primer Usuario (Administrador Total) |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-001, RNF-005 |

---

**Descripción**: El sistema debe permitir que el primer usuario se registre automáticamente como "Administrador Total" cuando la base de datos no contenga ningún usuario previo. Este escenario aplica cuando el cliente implementa Raccord por primera vez sin usuarios pre-cargados por los desarrolladores.


**Entradas**:
- Nombre (texto, máx 50 caracteres)
- Apellido (texto, máx 50 caracteres)
- Email (formato RFC 5322)
- Teléfono (formato internacional)
- Contraseña (mínimo 12 caracteres: 1 mayúscula, 1 minúscula, 1 número, 1 carácter especial)
- Confirmación de contraseña (debe coincidir con contraseña)
- Nombre del proyecto inicial (texto, máx 100 caracteres)

**Proceso**: Sistema verifica si existe algún usuario en la base de datos  
Si base de datos está vacía (primer usuario):
- Habilitar formulario de auto-registro sin restricciones
- Validar formato de email y unicidad
- Validar política de contraseña
- Hashear contraseña con bcrypt (12 rounds)
- Crear usuario con rol "Administrador Total" automáticamente
- Crear proyecto inicial automáticamente
- Asignar usuario como Administrador Total del proyecto
- Enviar email de confirmación
- Activar cuenta automáticamente.
Si ya existen usuarios:

- Deshabilitar auto-registro
- Mostrar mensaje: "Contacte al administrador del sistema para obtener acceso"

**Salidas**:

- Usuario creado con rol "Administrador Total" y estado "Activo"
- Proyecto inicial creado
- Usuario vinculado al proyecto
- Email de confirmación enviado
- Registro en log de auditoría

**Precondiciones**:

- Base de datos de usuarios debe estar vacía para ese proyecto.
- Sistema debe estar desplegado y accesible

**Postcondiciones**:

- Primer usuario queda registrado como Administrador Total
- Proyecto inicial queda creado
- Auto-registro queda deshabilitado automáticamente
- Usuario puede iniciar sesión inmediatamente

**Actores**: Productor de Línea o Jefe de Producción (primer usuario del cliente)

**Dependencias**: Ninguna (es el primer requisito funcional del sistema)
