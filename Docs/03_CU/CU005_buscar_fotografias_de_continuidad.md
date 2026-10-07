# CU005 — Buscar Fotografías de Continuidad

## Identificación

| Campo | Valor |
|---|---|
| ID | CU005 |
| Título | Buscar Fotografías de Continuidad |
| Módulo | Módulo 2: Continuidad Visual |
| Actor primario | Todos los usuarios autorizados |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos los usuarios autorizados
- **Secundario:** Motor búsqueda PostgreSQL, Sistema de caché (Redis), Sistema RBAC

#### Descripción

Permite a todos los usuarios autorizados buscar fotografías mediante filtros múltiples: Proyecto, Episodio, Escena, Toma, Personaje, Fecha de rodaje, Departamento (Vestuario/Maquillaje/Utilería/Set), Estado de Continuidad, o búsqueda libre en comentarios. El sistema devuelve resultados en vista de galería con miniaturas, ordenados por defecto por Escena > Toma > Personaje. El tiempo de respuesta debe ser <10 segundos incluso con 10,000+ fotografías en base de datos. Los usuarios con rol de Talento solo pueden buscar dentro de sus escenas asignadas.

#### Precondiciones

- Usuario autenticado con acceso a Continuidad Visual
- Talento: escenas asignadas en tabla TALENTO_ESCENAS
- Al menos 1 fotografía en proyecto activo
- Índices BD creados, sistema caché operativo

#### Postcondiciones

**Con resultados:**
- Query SQL ejecutada con filtros (AND)
- Filtro automático Talento aplicado
- Resultados en <10s (objetivo <5s)
- Galería con thumbnails (300x300px)
- Metadatos en hover
- Ordenados Escena>Toma>Personaje
- Paginación 50/página
- Búsquedas frecuentes cacheadas (TTL 5min)

**Sin resultados:**
- Mensaje sugerencia
- Opción limpiar filtros
- Registro en LOG

**Si excede 10s:**
- Indicador progreso
- Sugerencia refinar filtros
- Alerta a admins
- Registro en LOG

#### Flujo Principal

1. Usuario abre módulo "Continuidad Visual"
2. Usuario aplica filtros deseados: Proyecto, Episodio, Escena, Toma, Personaje, Fecha, Departamento, Estado
3. Usuario hace clic "Buscar"
4. Sistema construye query SQL con filtros (AND entre filtros)
5. Si usuario es Talento: sistema añade filtro automático "solo mis escenas"
6. Sistema ejecuta búsqueda en PostgreSQL
7. Sistema devuelve resultados en <10 segundos
8. Sistema muestra galería con thumbnails (300x300px)
9. Sistema ordena por: Escena (ASC) → Toma (ASC) → Personaje (ASC)
10. Sistema muestra contador "Mostrando X-Y de Z fotografías"
11. Sistema implementa paginación (50 resultados/página)

#### Flujos Alternativos

**FA-001: Búsqueda Guardada (Favoritos)** : Usuario guarda combinación de filtros → Asigna nombre → Sistema guarda en tabla BUSQUEDAS_FAVORITAS → Usuario accede desde "Mis Búsquedas" → Carga filtros automáticamente

#### Flujos Excepcionales

**FE-001: Timeout de Búsqueda (>10s)** : Sistema detecta exceso tiempo → Cancela query → Muestra "Búsqueda muy amplia, refina filtros" → Registra alerta Admins

**FE-002: Caché Redis No Disponible** : Sistema detecta Redis caído → Ejecuta búsqueda directa en PostgreSQL → Registra alerta técnicos → Funciona degradado (más lento)

#### Frecuencia

Alta
