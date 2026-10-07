# RF-026 — Subida y Control de Versiones de Guion

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-026 |
| Título | Subida y Control de Versiones de Guion |
| Módulo | Gestión de Guiones |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir a Primera AD y Script subir versiones del guion en formato PDF con control de versiones, historial completo y restricción de visibilidad según rol de usuario.

**Entradas**:
- Archivo de guion (formato PDF, máx 50 MB)
- Número de versión (texto, ej: v1.0, v1.1, v2.0)
- Fecha de emisión (fecha)
- Descripción de cambios principales (texto, máx 1000 caracteres)
- Estado (selección única): Borrador / Revisión / Aprobado / En Rodaje

**Proceso**:

- Validar que usuario sea Primera AD, Script O Director
- Validar formato de archivo (solo PDF)
- Validar tamaño de archivo (<50 MB)
- Si ya existe guion con mismo número de versión: rechazar y solicitar número diferente
- Almacenar PDF en storage seguro (S3 o equivalente) con cifrado
- Crear registro en base de datos con metadatos del guion
- Si estado = "En Rodaje":

        Marcar automáticamente versión anterior como "No visible para Talento"
        Esta versión se convierte en la visible para Talento
        Enviar notificación a todo el equipo de nueva versión disponible
- Mantener historial completo de versiones en orden cronológico
- Permitir descargar versiones anteriores (solo roles autorizados: Script, Primera AD, Dirección, Administrador Total)
- Usuarios con rol Talento solo pueden ver versión marcada como "En Rodaje"
- Registrar subida en log de auditoría

**Salidas**:

- Guion almacenado en storage con cifrado
- Metadatos del guion en base de datos
- Notificación enviada a equipo (si estado = En Rodaje)
- Historial de versiones actualizado
- Registro en log de auditoría

**Precondiciones**: Usuario debe ser Primera AD o Script y proyecto debe estar activo

**Postcondiciones**:

- Guion disponible para visualización según permisos de rol
- Versión "En Rodaje" es la única visible para Talento
- Historial completo accesible para roles autorizados

**Actores**:
- Primera Ayudante de Dirección (sube guiones)
- Script (sube guiones)
- Director (sube guiones)

**Dependencias**:

- RF-017 (Proyecto debe existir)
- RF-005 (Sistema de roles controla visibilidad)
- RF-009 (Log de auditoría)
