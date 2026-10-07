# RF-008 — Gestión de Perfil de Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-008 |
| Título | Gestión de Perfil de Usuario |
| Módulo | Autenticación y Gestión de Usuarios |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | RNF-033 |

---

**Descripción**: El sistema debe permitir a usuarios actualizar su información personal (datos de contacto, preferencias de notificación, foto de perfil) excepto datos críticos que solo puede modificar un Administrador Total.


**Entradas**:

- Teléfono (opcional, formato internacional)
- Foto de perfil (imagen JPG/PNG, máx 2 MB)
- Preferencias de notificación: Email (sí/no), Push (sí/no)
- Configuración de interfaz: Modo oscuro (sí/no)

**Proceso**:

- Validar que usuario esté autenticado.
- Mostrar formulario con datos actuales pre-cargados
- Usuario modifica campos editables
- Validar formato de teléfono si se proporciona
- Validar formato (JPG/PNG) y tamaño (<2 MB) de foto si se sube
- Comprimir foto a resolución óptima (500x500px) manteniendo calidad
- Actualizar solo campos modificados en base de datos

**Salidas**:

- Información de perfil actualizada en base de datos
- Foto de perfil almacenada en storage (S3 o equivalente)
- Mensaje de confirmación al usuario

**Precondiciones**: Usuario debe estar autenticado (RF-003) y el usuario debe tener sesión activa

**Postcondiciones**:

- Cambios reflejados inmediatamente en interfaz
- Cambios sincronizados automáticamente en todos los dispositivos del usuario

**Actores**: Todos los usuarios registrados

**Dependencias**: RF-003 (Usuario autenticado)

Campos NO Editables por Usuario:

- Email (solo Administrador Total puede cambiar)
- Nombre y Apellido (solo Administrador Total puede cambiar)
- Departamento (solo Administrador Total puede cambiar)
- Rol (solo Administrador Total puede cambiar)
- Proyectos asignados (solo Administrador Total puede cambiar)
