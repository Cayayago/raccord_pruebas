# RF-012 — Búsqueda Avanzada por Filtros

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-012 |
| Título | Búsqueda Avanzada por Filtros |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-008, RNF-020 |

---

**Descripción**: El sistema debe permitir a usuarios autorizados buscar fotografías de continuidad mediante filtros múltiples (individuales o combinados) con resultados devueltos en menos de 10 segundos (Tiempo que se busca).


**Entradas**:

- Filtros de búsqueda (opcionales, combinables)**:
- Proyecto (selección única)
- Episodio (selección única o múltiple)
- Número de Escena (número entero o rango)
- Número de Toma (número entero o rango)
- Personaje(s) (selección múltiple)
- Fecha de Rodaje (fecha única o rango)
- Departamento (Vestuario/Maquillaje/Utilería/Set)
- Estado de Continuidad (OK/Pendiente/Error)
- Búsqueda libre en comentarios (texto)


**Proceso**:

- Validar que usuario tenga permiso para buscar fotografías según su rol (RF-005)
- Usuarios con rol Talento: aplicar filtro automático "solo escenas donde están involucrados"
- Construir query SQL con filtros seleccionados (AND entre filtros)
- Ejecutar búsqueda en base de datos PostgreSQL con índices optimizados
- Ordenar resultados por defecto: Escena (ASC) → Toma (ASC) → Personaje (ASC)
- Devolver resultados en vista de galería con miniaturas (thumbnails 300x300px)
- Mostrar metadatos básicos en hover: Nomenclatura, Personaje, Estado
- Permitir cambio de vista: Galería / Lista / Comparación
- Implementar paginación (50 resultados por página)
- Si búsqueda tarda >10 segundos: mostrar indicador de progreso y sugerencia de refinar filtros

**Salidas**:

- Lista de fotografías que coinciden con filtros
- Miniaturas (thumbnails) de fotografías
- Metadatos básicos visibles por fotografía
- Contador de resultados encontrados
- Tiempo de búsqueda (para monitoreo de performance)

**Precondiciones**:

- Usuario debe estar autenticado (RF-004)
- Usuario debe tener permiso de búsqueda según su rol
- Debe existir al menos 1 fotografía en la base de datos

**Postcondiciones**:
- Resultados mostrados en menos de 10 segundos (Objetivo Específico 1)
- Usuario puede seleccionar fotografías para visualización.

**Actores**: Todos los usuarios autorizados (excepto Lectura General que no tiene acceso a fotografías)

**Dependencias**:

- RF-003 (Autenticación)
- RF-005 (Sistema de roles - Talento ve solo sus escenas)
- RF-010 (Fotografías deben estar cargadas)
