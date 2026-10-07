# CU006 — Visualizar y Comparar Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | CU006 |
| Título | Visualizar y Comparar Fotografías |
| Módulo | Módulo 2: Continuidad Visual |
| Actor primario | Todos los usuarios autorizados según rol |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos los usuarios autorizados según rol
- **Secundario:** Sistema storage, Sistema marca de agua, Sistema de LOG

#### Descripción

Permite a todos los usuarios autorizados visualizar fotografías en alta resolución con zoom, rotación y navegación secuencial (anterior/siguiente). El sistema muestra metadatos completos al lado de la imagen: nomenclatura, personajes, detalle, fecha, estado, comentarios, historial de versiones. Adicionalmente, permite comparación lado a lado de hasta 4 fotografías simultáneamente para detectar inconsistencias visuales. La visualización siempre incluye marca de agua dinámica superpuesta (no descargable sin marca). Los Jefes de Departamento pueden añadir comentarios específicos a cualquier fotografía.

#### Precondiciones

- Usuario autenticado con permiso visualización según rol
- Fotografía(s) existe(n) con estado "Activa"
- Talento: foto de escena asignada
- Storage accesible
- Para comparación: 2-4 fotos seleccionadas

#### Postcondiciones

**Visualización individual:**
- Imagen cargada (<5s con 10Mbps)
- Marca de agua dinámica (usuario+timestamp+proyecto, posición aleatoria, 30-40% opacidad)
- Metadatos en panel lateral
- Controles disponibles (zoom, rotación, navegación, fullscreen)
- Capturas bloqueadas (móvil) o click derecho deshabilitado (web)
- Registro en LOG
- Si Jefe Depto añade comentario: Guardado en BD, notificación a Script, visible para todos autorizados

**Comparación 2-4 fotos:**
- Vista dividida, mismo tamaño
- Zoom/scroll sincronizado
- Metadatos bajo cada imagen
- Posiciones intercambiables (drag&drop)
- Exportable a PDF (Script/Jefe Depto) con marca de agua reforzada
- Registro en LOG

#### Flujo Principal (Visualizar)

1. Usuario hace clic en fotografía desde galería
2. Sistema carga imagen alta resolución desde storage
3. Sistema aplica marca de agua dinámica en tiempo real (posición aleatoria)
4. Sistema muestra imagen en visor con metadatos en panel lateral
5. Sistema habilita controles: zoom, rotación, navegación, fullscreen
6. Sistema bloquea capturas de pantalla (móvil) o click derecho (web)
7. Sistema registra visualización en LOG (quién, qué, cuándo)

#### Flujo Principal (Comparar)

1. Usuario selecciona 2-4 fotografías desde galería
2. Usuario hace clic "Comparar"
3. Sistema carga fotografías seleccionadas
4. Sistema muestra vista dividida (2, 3 o 4 columnas)
5. Sistema aplica marca de agua a todas las imágenes
6. Sistema sincroniza zoom y scroll entre todas las imágenes
7. Sistema muestra metadatos básicos bajo cada imagen
8. Sistema permite intercambiar posiciones (drag&drop)
9. Sistema registra comparación en LOG

#### Flujos Alternativos

**FA-001: Comparación con Anotaciones Temporales** : Durante comparación → Usuario dibuja círculos/flechas sobre fotos → Marcas NO se guardan → Solo para referencia visual temporal → Se pierden al cerrar

**FA-002: Navegación Secuencial en Visor** : Usuario visualiza foto → Usa teclas ←/→ o botones → Sistema carga anterior/siguiente de la galería actual → Mantiene contexto de búsqueda

#### Flujos Excepcionales

**FE-001: Imagen No Disponible en Storage** : Sistema intenta cargar foto → Storage no responde → Muestra "Imagen temporalmente no disponible" → Registra error → Alerta técnicos

**FE-002: Intento Captura de Pantalla** : Usuario intenta captura (móvil) → Sistema detecta → Pantalla negra momentánea → Muestra alerta "Capturas no permitidas" → Registra intento en LOG

#### Frecuencia

Alta
