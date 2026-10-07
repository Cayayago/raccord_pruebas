# CU013 — Gestionar Versiones de Guion

## Identificación

| Campo | Valor |
|---|---|
| ID | CU013 |
| Título | Gestionar Versiones de Guion |
| Módulo | Módulo 4: Gestión de Guiones |
| Actor primario | Administrador y Sub admi |
| Frecuencia | Baja |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador y Sub admi
- **Secundario:** Sistema storage, Sistema versionado, Sistema notificaciones, Sistema LOG

#### Descripción

Permite a la Primera AD, Script y Director subir versiones del guion en formato PDF. Cada versión tiene: número de versión, fecha de emisión, descripción de cambios principales, y estado (Borrador/Revisión/Aprobado/En Rodaje). El sistema mantiene historial completo de versiones con posibilidad de descargar versiones anteriores (solo para roles autorizados). Solo la versión marcada como "En Rodaje" es visible para Talento. El guion siempre se visualiza dentro de la app con marca de agua dinámica. El sistema desactiva capturas de pantalla en apps móviles y click derecho en web.

#### Precondiciones

- Ejecutor Primera AD/Script/Director autenticado
- Proyecto activo seleccionado
- Archivo PDF válido ≤50 MB
- Número versión único en proyecto

#### Postcondiciones

**Subida nueva versión:**
- Formulario completado (PDF, versión ej:v1.0, fecha emisión, descripción 1000 chars, estado:Borrador/Revisión/Aprobado/En Rodaje)
- Validaciones ejecutadas (formato/tamaño/versión única)
- PDF en storage cifrado (AES-256)
- Registro BD con metadatos+UUID
- Si estado="En Rodaje": versión anterior→"No visible Talento", nueva→visible Talento
- Notificación push todo equipo
- Historial actualizado
- Registro en LOG

**Descarga versión anterior:**
- Solo Script/AD/Dir/Admin
- Permiso verificado
- PDF con marca de agua reforzada
- Descarga en LOG
- Si no autorizado: mensaje error

**Talento visualiza:**
- Solo versión "En Rodaje" visible
- Anteriores ocultas
- Marca de agua con nombre actor
- Capturas bloqueadas
- Visualización en LOG

#### Flujo Principal

1. Primera AD/Script/Director hace clic "Subir Guion"
2. Sistema muestra formulario
3. Usuario completa: Archivo PDF (≤50MB), Versión (ej: v1.0), Fecha emisión, Descripción cambios (1000 chars), Estado (Borrador/Revisión/Aprobado/En Rodaje)
4. Usuario hace clic "Subir"
5. Sistema valida formato PDF, tamaño ≤50MB, versión única
6. Sistema almacena PDF en storage cifrado (AES-256)
7. Sistema crea registro en BD con metadatos + UUID
8. Si estado="En Rodaje": sistema marca versión anterior como "No visible para Talento"
9. Sistema envía notificación push a todo el equipo
10. Sistema actualiza historial de versiones
11. Sistema registra subida en LOG

#### Flujos Alternativos

**FA-001: Reversión a Versión Anterior** : Script/AD selecciona versión antigua → "Restaurar como Actual" → Sistema crea nueva versión (copia) con num incremental → Marca "En Rodaje"

#### Flujos Excepcionales

**FE-001: PDF Corrupto o Ilegible** : Sistema intenta procesar PDF → Detecta archivo corrupto → Rechaza subida → Muestra "Archivo dañado, intenta nuevamente"

**FE-002: Versión Duplicada** : Sistema detecta num_versión ya existe → Rechaza → Muestra "Versión ya registrada" → Sugiere incrementar número

#### Frecuencia

Baja
