# RF-030 — Vinculación Automática Guion-Continuidad

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-030 |
| Título | Vinculación Automática Guion-Continuidad |
| Módulo | Gestión de Guiones |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe vincular automáticamente cada escena del guion con las fotografías de continuidad correspondientes mediante match por número de escena, con navegación bidireccional.


**Entradas**:

- Guion abierto en visor (RF-027)
- Número de escena detectado automáticamente en el PDF o ingresado manualmente

**Proceso**:

- Al visualizar guion: sistema identifica automáticamente números de escena mediante:

        Patrón regex: "INT.", "EXT.", "ESC.", "ESCENA", seguido de número
        Ejemplo: "INT. OFICINA - DÍA" → detecta número de escena
- Si detección automática falla: Script puede etiquetar manualmente escenas en el guion
- Para cada escena detectada, mostrar botón "Ver Continuidad" al lado del número de escena
- Al hacer clic en "Ver Continuidad":

- Abrir vista lateral (split screen)
- Ejecutar búsqueda automática en base de fotografías (RF-012) filtrando por número de escena
- Mostrar galería de todas las fotografías de esa escena organizadas por:

        Personaje
        Tipo de Detalle (Vestuario, Maquillaje, Utilería, Set)
        Toma

- Permitir navegación bidireccional:

        Desde guion → fotografías de continuidad (descrito arriba)
        Desde fotografía → escena del guion: botón "Ver Escena en Guion" en RF-010
- Mantener sincronización: si usuario está en Escena 5 del guion y navega a fotografía, al volver al guion debe regresar a Escena 5

**Salidas**:
- Vista lateral con fotografías de continuidad de la escena
- Navegación bidireccional funcional
- Sincronización de posición entre guion y fotografías

**Precondiciones**:
- Guion debe estar subido (RF-026)
- Fotografías de continuidad deben existir (RF-010)
- Números de escena deben coincidir entre guion y fotografías

**Postcondiciones**: Departamentos pueden revisar simultáneamente qué dice el guion y cómo se ejecutó visualmente

**Actores**: Todos los usuarios que visualizan guiones

**Dependencias**:

- RF-027 (Visualización de guion)
- RF-012 (Búsqueda de fotografías)
- RF-010 (Visualización de fotografías)
