# RF-025 — Directorio de Equipo (Crew List)

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-025 |
| Título | Directorio de Equipo (Crew List) |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Baja |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**:El sistema debe mantener un directorio completo del equipo de producción con información de contacto, consultable por todos los usuarios y editable solo por Coordinadores de Departamento y Productor de Línea.


**Entradas**:
- Nombre completo (texto, máx 100 caracteres)
- Cargo (texto, máx 100 caracteres, ej: "Gaffer", "Key Grip", "Script Supervisor")
- Departamento (selección única): Vestuario/Maquillaje/Utilería/Fotografía/Arte/Dirección/Producción/Sonido/Edición
- Rol en el sistema (si está registrado): vinculación con RF-005
- Teléfono de contacto (formato internacional)
- Email (formato RFC 5322)
- Notas adicionales (texto, máx 300 caracteres, opcional)

**Proceso**:

- Validar que usuario sea Coordinador de Departamento, Primera AD o Administrador Total
- Permitir añadir miembros del equipo al directorio
- Si miembro ya está registrado en sistema (RF-003): vincular automáticamente y pre-completar datos
- Si miembro NO está registrado: permitir añadir solo datos de contacto (no tiene acceso al sistema)
- Organizar directorio por departamento
- Permitir búsqueda por: nombre, cargo, departamento, teléfono
- Todos los usuarios pueden consultar directorio completo
- Solo Coordinadores y Administrador Total pueden: añadir, editar, eliminar miembros
- Exportar directorio en formato Excel o PDF (todos los usuarios)

**Salidas**:
- Directorio completo del equipo consultable
- Búsqueda rápida de contactos
- Exportación en Excel/PDF

**Precondiciones**: Usuario debe estar autenticado y proyecto debe estar activo

**Postcondiciones**:

- Equipo completo visible para coordinación
- Contactos accesibles rápidamente en rodaje

**Actores**:

- Todos los usuarios (consulta)
- Coordinadores de Departamento, Primera AD, Administrador Total (edición)

**Dependencias**:

- RF-003 (Puede vincularse con usuarios registrados)
- RF-003 (Usuario autenticado)
