# RF-011 — Gestión de Nomenclatura y Versionado de Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-011 |
| Título | Gestión de Nomenclatura y Versionado de Fotografías |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**

El sistema debe generar automáticamente una nomenclatura única y estandarizada para cada fotografía de continuidad, y gestionar el versionado completo de las mismas, permitiendo mantener un historial detallado, visualizar, comparar y restaurar versiones anteriores sin pérdida de información.

→ Alta

**Entradas**

- Metadatos de fotografía:
  - Proyecto  
  - Episodio  
  - Escena  
  - Toma  
  - Personaje  
  - Detalle  

- Fotografía cargada  
- Fotografías existentes en base de datos  

- Acción del usuario:
  - Ver historial  
  - Comparar versiones  
  - Restaurar versión (solo Script)  

**Proceso**

#### Generación de nomenclatura automática

- Extraer y formatear metadatos:
  - PROYECTO: generar automáticamente, dependiendo en el proyecto que este ubicado (Incluido ID_Project)
  - EPISODIO: formato EP## o NA  
  - ESCENA: ESC###  
  - TOMA: T##  
  - PERSONAJE: sin espacios, máx 15 caracteres  
  - DETALLE: VEST, MAQ, UTIL, SET, OTRO  
  - VERSION: autoincremental (V1, V2, V3...)  

- Generar nomenclatura:

- Validar en base de datos:
  - Si existe misma nomenclatura base → incrementar versión  
  - Si no existe → asignar V1  

- Renombrar automáticamente el archivo con la nomenclatura generada  

#### estión de versionado

- Si se carga una fotografía con misma nomenclatura base:
  - Crear nueva versión (V2, V3…)  
  - Marcar versión anterior como Histórica  
  - Mantener todas las versiones (NO eliminar)  

#### Visualización de historial

- Mostrar botón "Ver Historial"  
- Listar versiones en orden cronológico inverso:
  - Nomenclatura completa  
  - Fecha y hora  
  - Usuario  
  - Comentarios  


#### Comparación de versiones

- Permitir comparar versiones (actual vs anterior)  
- Integración con RF-015  


#### Restauración de versiones

- Solo el actor Script puede restaurar:
  - Versión seleccionada → Actual  
  - Versión actual → Histórica  

- Registrar acción en log de auditoría  


**Salidas**

- Nomenclatura única generada  
- Archivo renombrado automáticamente  
- Historial completo de versiones  
- Comparación visual entre versiones  
- Versión restaurada (si aplica)  
- Registro en log de auditoría  

**Precondiciones**
- Metadatos completos (RF-010)  
- Debe existir al menos una fotografía para historial  
- Para restauración: actor debe ser Script  


**Postcondiciones**
- Todas las fotografías tienen nomenclatura única  
- Historial completo disponible (trazabilidad total)  
- Versiones anteriores NO se eliminan  
- Búsqueda eficiente por nomenclatura  


**Actores**

- Usuarios: visualizar historial y comparar  
- Script: restaurar versiones  
- Sistema: generar nomenclatura y versionado automático  


**Dependencias**

- RF-010: Carga de fotografías
