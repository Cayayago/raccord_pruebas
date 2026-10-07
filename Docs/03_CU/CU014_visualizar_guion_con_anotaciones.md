# CU014 — Visualizar Guion con Anotaciones

## Identificación

| Campo | Valor |
|---|---|
| ID | CU014 |
| Título | Visualizar Guion con Anotaciones |
| Módulo | Módulo 4: Gestión de Guiones |
| Actor primario | Todos usuarios autorizados según rol |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos usuarios autorizados según rol
- **Secundario:** Sistema visor PDF, Sistema marca de agua, Sistema anotaciones, Sistema sincronización, Sistema LOG

#### Descripción

Permite a todos los usuarios autorizados visualizar el guion en visor PDF integrado dentro de la app. Los usuarios pueden realizar anotaciones personales (notas, resaltados, marcadores) que solo ellos ven. Los Jefes de Departamento pueden crear anotaciones departamentales (visibles para todo su equipo). El Script puede crear anotaciones generales visibles para todos los roles. Las anotaciones se sincronizan entre dispositivos del mismo usuario. El Talento solo puede anotar en sus escenas asignadas.

#### Precondiciones

- Usuario autenticado con permiso visualización según rol
- Guion subido al sistema (CU013)
- Talento: guion estado "En Rodaje"
- Storage accesible

#### Postcondiciones

**Visualización:**
- PDF desde storage
- Visor integrado (NO descarga externa)
- Marca de agua dinámica cada página (usuario+timestamp+proyecto, diagonal 30-40% opacidad)
- Controles (navegación/zoom/búsqueda texto)
- Anotaciones cargadas
- Capturas bloqueadas móvil (pantalla negra)
- Click derecho/atajos deshabilitados web
- Visualización en LOG (quién/versión/timestamp/duración/IP/dispositivo)

**Anotación personal:**
- Menú contextual (Nota/Resaltado/Marcador)
- Si Nota: pop-up 500 chars→guardada BD (usuario/guion/página/coords/tipo/contenido/visibilidad:Personal)
- Si Resaltado: color seleccionable→coords guardadas
- Si Marcador: página marcada→panel lateral
- Sincronizada todos dispositivos usuario

**Anotación departamental:**
- Solo Jefes Depto
- Visibilidad:Departamental
- Visible equipo depto+Script+Admin
- Notificación equipo
- Icono🔵

**Anotación general:**
- Solo Script
- Visibilidad:General
- Visible TODOS roles
- Notificación push todo equipo
- Icono🔴

**Editar/Eliminar:**
- Solo propias
- Otras solo lectura
- Al eliminar: borrada BD, sincronizada dispositivos

#### Flujo Principal (Visualizar)

1. Usuario selecciona versión de guion desde lista
2. Sistema valida permiso de visualización según rol
3. Sistema carga PDF desde storage
4. Sistema muestra visor PDF integrado
5. Sistema aplica marca de agua dinámica en cada página (usuario+timestamp+proyecto)
6. Sistema carga anotaciones existentes (personal, departamental, general según rol)
7. Sistema habilita controles: navegación, zoom, búsqueda texto
8. Sistema bloquea capturas (móvil) o click derecho (web)
9. Sistema registra visualización en LOG

#### Flujo Principal (Anotar)

1. Usuario selecciona texto o hace clic en página
2. Sistema muestra menú contextual: Nota / Resaltado / Marcador
3. Usuario elige opción (ej: "Nota")
4. Sistema muestra pop-up para ingresar texto (500 chars)
5. Usuario ingresa contenido y hace clic "Guardar"
6. Sistema guarda anotación en BD con: usuario, guion, página, coords, tipo, contenido, visibilidad
7. Sistema renderiza anotación con icono según visibilidad
8. Sistema sincroniza anotación en todos los dispositivos del usuario

#### Flujos Alternativos

**FA-001: Filtrar Anotaciones por Tipo** : Usuario activa filtro → Muestra solo: Personales / Departamentales / Generales / Todas → Vista actualizada

**FA-002: Exportar Anotaciones a PDF** : Script exporta anotaciones generales → Sistema genera PDF (página+anotación+autor) → Descarga con marca de agua

#### Flujos Excepcionales

**FE-001: Talento Intenta Anotar Escena No Asignada** : Sistema detecta escena no pertenece a actor → Bloquea anotación → Muestra "Solo puedes anotar tus escenas asignadas"

**FE-002: Conflicto Anotación Simultánea** : Dos usuarios anotan mismo punto → Sistema detecta coords similares → Guarda ambas desplazadas → Notifica conflicto

#### Frecuencia

Alta
