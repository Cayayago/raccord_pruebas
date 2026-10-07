# CU004 — Gestionar Fotografías de Continuidad

## Identificación

| Campo | Valor |
|---|---|
| ID | CU004 |
| Título | Gestionar Fotografías de Continuidad |
| Módulo | Módulo 2: Continuidad Visual |
| Actor primario | onset y usuario |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** onset y usuario
- **Secundario:** Sistema de storage, Sistema de marca de agua, Sistema de notificaciones, Sistema de LOG

#### Descripción

Permite al Script, Jefes de Departamento y Asistentes Onset subir fotografías de continuidad desde dispositivos móviles o tablets. Al subir, el sistema solicita completar campos obligatorios: Proyecto, Episodio, Escena, Toma, Personaje(s), Detalle (vestuario/maquillaje/utilería/set), Estado de Continuidad (OK/Pendiente/Error), y Comentarios adicionales. El sistema genera automáticamente la nomenclatura estandarizada: `PROYECTO_EPISODIO_ESCENA_TOMA_PERSONAJE_DETALLE_VERSION` y aplica marca de agua no removible con usuario y timestamp. Las fotografías se pueden modificar (actualizar metadatos, añadir comentarios) o marcar como "Versión anterior" cuando se sube una nueva versión del mismo detalle. Solo el Script puede eliminar fotografías (quedan en papelera por 30 días).

#### Precondiciones

- Usuario autenticado con rol autorizado (Script/Jefe Depto/Asistente Onset)
- Proyecto activo seleccionado
- Personajes registrados en tabla PERSONAJES
- Espacio storage ≥50 MB, almacenamiento local ≥100 MB (offline)
- No excedió límite 100 fotos/día

#### Postcondiciones

**Subida online:**
- Foto en storage con nomenclatura
- Versión auto-incrementada (V1→V2)
- Metadatos en BD
- Marca de agua aplicada
- Archivo original cifrado (AES-256)
- Hash SHA-256 calculado
- Visible en búsquedas
- Registro en LOG
- Si Estado="Error": Notificación urgente a Jefe Depto según tipo detalle, marcada "Bloqueante" en reportes

**Subida offline:**
- Foto en almacenamiento local (SQLite)
- Marcada "Pendiente sincronización"
- Sincroniza automáticamente al reconectar

**Modificación:**
- Campos actualizados
- Timestamp modificado
- Registro en LOG

**Eliminación:**
- Estado "Eliminada"
- Movida a papelera (30 días)
- Excluida de búsquedas
- Registro en LOG

#### Flujo Principal (Subir)

1. Usuario abre módulo "Continuidad Visual"
2. Usuario hace clic "Subir Fotografía"
3. Sistema muestra opciones: "Tomar Foto" o "Seleccionar de Galería"
4. Usuario selecciona opción y captura/selecciona foto
5. Sistema muestra preview y formulario de metadatos
6. Usuario completa campos obligatorios: Proyecto, Episodio, Escena, Toma, Personaje(s), Tipo Detalle, Estado, Comentarios
7. Usuario hace clic "Guardar"
8. Sistema valida campos completos y formato/tamaño archivo
9. Sistema genera nomenclatura: `PROYECTO_EPISODIO_ESCENA_TOMA_PERSONAJE_DETALLE_VERSION`
10. Sistema verifica duplicados y asigna/incrementa versión (V1, V2...)
11. Sistema aplica marca de agua (usuario + timestamp + proyecto)
12. Sistema sube foto a storage cifrado
13. Sistema guarda metadatos en BD
14. Sistema registra acción en LOG
15. Si Estado="Error": sistema notifica a Jefe de Departamento
16. Sistema muestra mensaje "Fotografía subida exitosamente"

#### Flujos Alternativos

**FA-001: Subida Masiva de Fotografías** : Usuario selecciona múltiples fotos (hasta 50) → Sistema procesa en lote → Aplica nomenclatura secuencial → Muestra progreso → Notifica completado

**FA-002: Modo Offline - Sincronización Posterior** : Usuario sin conexión → Fotos almacenadas SQLite local → Al reconectar, sistema detecta pendientes → Sincroniza automáticamente → Notifica éxito/errores

**FA-003: Actualizar Metadatos sin Subir Nueva Versión** : Usuario selecciona foto → "Editar Metadatos" → Modifica campos → Sistema actualiza BD sin crear nueva versión → Registra LOG

#### Flujos Excepcionales

**FE-001: Fotografía Marcada "Bloqueante"** : Jefe Depto marca estado "Error" → Sistema genera notificación urgente a Script y AD → Foto destacada en rojo en galería → Requiere resolución antes de continuar escena

**FE-002: Límite 100 Fotos/Día Excedido** : Sistema detecta límite → Bloquea subida → Muestra "Límite diario alcanzado. Contacta Admin para ampliar cuota"

**FE-003: Storage Sin Espacio** : Sistema detecta storage <50MB → Bloquea subida → Alerta Admins → Muestra "Espacio insuficiente, contacta soporte técnico"

**FE-004: Fallo Aplicación Marca de Agua** : Sistema no puede aplicar marca → Rechaza subida → Registra error crítico → Alerta técnicos → No guarda foto sin marca

#### Frecuencia

Alta
