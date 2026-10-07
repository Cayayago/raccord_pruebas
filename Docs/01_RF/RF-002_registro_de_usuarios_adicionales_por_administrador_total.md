# RF-002 — Registro de Usuarios Adicionales por Administrador Total

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-002 |
| Título | Registro de Usuarios Adicionales por Administrador Total |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir a usuarios con rol "Administrador Total" registrar nuevos usuarios en la plataforma, asignándoles un rol específico dentro de la jerarquía de producción audiovisual y vinculándolos a uno o más proyectos activos. Este requisito aplica después de que el primer administrador ya existe.


**Entradas**:
- Nombre (texto, máx 50 caracteres)
- Apellido (texto, máx 50 caracteres)
- Email (formato RFC 5322)
- Teléfono (formato internacional)
- Departamento (Vestuario/Maquillaje/Utilería/Fotografía/Arte/Dirección/Producción)
- Rol (Administrador Total/Continuidad Total/Jefe de Departamento/Asistente de Departamento/Dirección/Talento/Lectura General)
- Proyecto(s) asignado(s) (selección múltiple)

**Proceso**:
- Validar que usuario ejecutor tenga rol "Administrador Total"
- Validar formato de email y unicidad en base de datos
- Validar que campos obligatorios estén completos
- Generar contraseña temporal aleatoria (12 caracteres: 1 mayúscula, 1 minúscula, 1 número, 1 carácter especial)
- Crear registro de usuario con estado "Inactivo"
- Enviar email con credenciales y enlace de activación
- Registrar acción en log de auditoría (quién creó el usuario, cuándo, con qué rol)

**Salidas**:
- Usuario creado en base de datos con estado "Inactivo"
- Email de activación enviado al usuario nuevo
- Mensaje de confirmación al administrador
- Registro en log de auditoría

**Precondiciones**:
- Usuario ejecutor debe tener rol "Administrador Total"
- Usuario ejecutor debe estar autenticado
- Debe existir al menos un proyecto activo en el sistema
- Ya debe existir al menos 1 usuario Administrador Total en el sistema (RF-001 o RF-002 ejecutado)

**Postcondiciones**:

Usuario nuevo queda registrado en estado "Inactivo" hasta activación. Si el usuario no activa cuenta en 48 horas, registro se elimina automáticamente

**Actores**: Administrador Total (Productor de Línea, Jefe de Producción)

**Dependencias**: RF-001 (debe existir al menos un Administrador Total)
