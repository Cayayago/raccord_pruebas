# CU016 — Vincular Guion con Continuidad

## Identificación

| Campo | Valor |
|---|---|
| ID | CU016 |
| Título | Vincular Guion con Continuidad |
| Módulo | Módulo 4: Gestión de Guiones |
| Actor primario | Todos usuarios visualizando guiones |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos usuarios visualizando guiones
- **Secundario:** Motor de detección de escenas por patrones (regex), Sistema búsqueda fotos (CU005), Sistema vinculación bidireccional

#### Descripción

El sistema vincula automáticamente cada escena del guion con las fotografías de continuidad correspondientes (match por número de escena). Al visualizar una escena en el guion, el usuario puede hacer clic en "Ver Continuidad" y el sistema abre una vista lateral con todas las fotografías de esa escena organizadas por personaje y detalle. El vínculo es bidireccional: desde las fotografías también se puede acceder a la escena correspondiente del guion.

#### Precondiciones

- Guion subido (CU013)
- Usuario visualizando guion (CU014)
- Fotografías existen para ≥1 escena
- Números escena coinciden guion-fotos

#### Postcondiciones

**Detección auto escenas:**
- Al subir/abrir guion: motor de patrones ejecutado
- Regex aplicado ("INT.","EXT.","ESC.","ESCENA"+número)
- Números extraídos→tabla ESCENAS_GUION
- Si falla: Script etiqueta manual (modal ingresa número)

**"Ver Continuidad" desde guion:**
- Botón junto a num_escena
- Click→búsqueda auto CU005 (WHERE escena=actual)
- Vista dividida (izq:guion posición actual, der:galería fotos)
- Fotos organizadas (Personaje>Detalle>Toma)
- Navegación sin cerrar guion
- Sincronización posición

**"Ver Escena en Guion" desde foto:**
- Metadatos muestran "Escena[X]"+botón
- Click→abre guion CU014+navega auto a escena
- Escena resaltada (fondo amarillo)
- Vista dividida opcional (foto|guion)

**Navegación bidireccional:**
- Vínculo mantenido sesión
- Posición preservada
- Breadcrumbs mostrados

**Si escena sin fotos:**
- Botón deshabilitado (gris)
- Tooltip "No hay fotos"
- Sugerencia subir (si permiso)

#### Flujo Principal (Detección automática)

1. Usuario sube guion o abre por primera vez (CU013)
2. Sistema ejecuta detección automática por patrones de texto
3. Sistema aplica regex: "INT.", "EXT.", "ESC.", "ESCENA" + número
4. Sistema extrae números de escena
5. Sistema guarda números en tabla ESCENAS_GUION
6. Sistema vincula automáticamente con fotografías (match por num_escena)

#### Flujo Principal (Ver Continuidad desde guion)

1. Usuario está visualizando guion (CU014)
2. Usuario hace clic botón "Ver Continuidad" junto a número de escena
3. Sistema ejecuta búsqueda automática (CU005) con filtro WHERE escena=actual
4. Sistema muestra vista dividida: izquierda (guion), derecha (galería fotos)
5. Sistema organiza fotos por: Personaje > Detalle > Toma
6. Usuario navega fotos sin cerrar guion
7. Posición del guion se mantiene sincronizada

#### Flujo Principal (Ver Guion desde foto)

1. Usuario visualiza fotografía (CU006)
2. Usuario hace clic botón "Ver Escena en Guion" en metadatos
3. Sistema abre guion (CU014)
4. Sistema navega automáticamente a la escena correspondiente
5. Sistema resalta escena con fondo amarillo
6. Usuario puede ver foto y guion simultáneamente

#### Flujos Alternativos

**FA-001: Corrección Manual Vinculación** : Script detecta num_escena incorrecto → Edita foto → Cambia num_escena → Sistema actualiza vínculo automáticamente

#### Flujos Excepcionales

**FE-001: Detección por Patrones No Encuentra Escenas** : Sistema ejecuta regex → No encuentra patrones → Notifica Script → Modal permite etiquetado manual página por página

**FE-002: Múltiples Escenas en Misma Página** : Detección por patrones encuentra 2+ nums escena misma página → Sistema vincula a primera → Alerta Script para revisar

#### Frecuencia

Alta
