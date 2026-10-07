# RF-013 — Comparación Visual Lado a Lado

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-013 |
| Título | Comparación Visual Lado a Lado |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | RNF-006 |

---

**Descripción**: El sistema debe permitir comparar hasta 2 fotografías simultáneamente en vista lado a lado con zoom sincronizado para detectar inconsistencias visuales entre tomas de una misma escena.


**Entradas**:
- 2, 3 o 4 fotografías seleccionadas desde RF-012 (Búsqueda)
- Acciones del usuario: Zoom sincronizado, Intercambio de posiciones

**Proceso**:

- Validar que usuario tenga permiso para comparar fotografías
- Cargar fotografías seleccionadas en vista lado a lado
- Mostrar todas las imágenes con mismo tamaño de visualización
- Aplicar marca de agua dinámica a todas las imágenes
- Implementar zoom sincronizado: si usuario hace zoom en una, se replica automáticamente en todas
- Permitir intercambiar posiciones de imágenes arrastrando
- Mostrar metadatos debajo de cada imagen: Nomenclatura, Escena, Toma, Personaje, Estado
- Permitir exportar comparación como PDF (solo roles autorizados: Script, Jefes de Departamento)
- Si se exporta: aplicar marca de agua reforzada en múltiples puntos

**Salidas**:

- Vista comparativa de 2-4 fotografías lado a lado
- Zoom sincronizado entre todas las imágenes
- PDF de comparación (si usuario exporta y tiene permiso)
- Registro de comparación en log de auditoría

**Precondiciones**:

- Usuario debe estar autenticado (RF-004)
- Usuario debe tener permiso según su rol
- Deben existir al menos 2 fotografías seleccionadas

**Postcondiciones**:

- Usuario puede identificar visualmente inconsistencias entre tomas
- Exportación de comparación queda registrada en auditoría

**Actores**: Script, Jefes de Departamento, Director de Fotografía, Director

**Dependencias**:

- RF-003 (Autenticación)
- RF-005 (Sistema de roles)
- RF-012 (Búsqueda de fotografías)
