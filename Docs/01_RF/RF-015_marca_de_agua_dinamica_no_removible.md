# RF-015 — Marca de Agua Dinámica No Removible

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-015 |
| Título | Marca de Agua Dinámica No Removible |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-015, RNF-018 |

---

**Descripción**: El sistema debe aplicar marca de agua dinámica en tiempo real (superpuesta, NO incrustada en archivo original) a todas las fotografías y guiones descargados para proteger contenido confidencial y garantizar trazabilidad.


**Entradas**:
- Fotografía o guion a visualizar
- Usuario que visualiza (capturado automáticamente)
- Timestamp de visualización (capturado automáticamente)

**Proceso**:

- Al cargar imagen o documento en visor:

        Aplicar capa superpuesta (overlay) con marca de agua en tiempo real
        NO modificar archivo original almacenado


- Marca de agua debe incluir:

        Nombre completo del usuario que visualiza
        Nombre del proyecto


- Características de la marca:

        Semi-transparente (opacidad 30-40%)
        Color: blanco con borde negro (legible sobre cualquier fondo)
        Fuente: Sans-serif, tamaño 14-16px
        Posición: aleatoria cada vez (no siempre en mismo lugar para dificultar eliminación)
        Se repite múltiples veces en diagonal sobre la imagen


- En aplicaciones móviles (iOS/Android): deshabilitar capturas de pantalla a nivel de sistema operativo.
- En la app de escritorio (Windows/macOS, Flutter): deshabilitar clic derecho e interceptar atajos de captura/impresión (Ctrl+S, Ctrl+P, PrtScr) dentro de la app; a diferencia de móvil, el sistema operativo de escritorio no ofrece una API para bloquear capturas de forma garantizada, por lo que esto es un disuasivo y la marca de agua sigue siendo la protección principal (ver RNF-015).
- Si usuario intenta exportar (solo roles autorizados): aplicar marca de agua.

**Salidas**:

- Imagen/documento con marca de agua visible
- Archivo original sin marca permanece intacto en storage
- Registro de visualización en log de auditoría (RF-009)

**Precondiciones**:

- Usuario debe estar autenticado
- Contenido debe estar almacenado en sistema

**Postcondiciones**:

- Contenido visualizado tiene trazabilidad completa (quién lo vio, cuándo)
- Capturas de pantalla bloqueadas en móviles
- Archivo original protegido de modificación

**Actores**: Todos los usuarios que visualizan contenido

**Dependencias**:

- RF-010 (Visualización de fotografías)
- Librería de procesamiento de imágenes (Pillow para Python)
