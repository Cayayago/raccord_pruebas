# RF-029 — Comparación de Versiones de Guion (Diff)

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-029 |
| Título | Comparación de Versiones de Guion (Diff) |
| Módulo | Gestión de Guiones |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**:El sistema debe permitir al Script y Primera AD visualizar diferencias entre dos versiones del guion mediante comparación visual lado a lado con resaltado de colores para texto eliminado, nuevo y modificado.


**Entradas**:
- Versión 1 del guion (selección de versión antigua)
- Versión 2 del guion (selección de versión nueva)

**Proceso**:

- Validar que usuario sea Script o Primera AD
- Cargar ambas versiones del guion desde storage
- Extraer texto de ambos PDFs mediante OCR o extracción de texto nativo
- Ejecutar algoritmo diff (diferencias línea por línea):

        Texto eliminado (presente en V1, ausente en V2): resaltar en rojo
        Texto nuevo (ausente en V1, presente en V2): resaltar en verde
        Texto modificado (cambio parcial): resaltar en amarillo
        Texto sin cambios: sin resaltado
- Mostrar comparación en vista lado a lado:

        Columna izquierda: Versión anterior
        Columna derecha: Versión nueva
        Scroll sincronizado entre ambas columnas
- Mostrar índice de cambios:

        Lista de páginas con cambios
        Cantidad de cambios por página
        Navegación rápida a páginas con cambios
- Permitir generar "Reporte de Cambios" en PDF:

        Lista textual de todos los cambios
        Formato: "Página X, Línea Y: [Texto eliminado] → [Texto nuevo]"
        Exportar con marca de agua
- Registrar comparación en log de auditoría

**Salidas**:

- Vista comparativa lado a lado con resaltado de diferencias
- Índice de cambios por página
- Reporte de Cambios en PDF (si usuario lo genera)
- Registro en log de auditoría

**Precondiciones**:

- Usuario debe ser Script o Primera AD
- Deben existir al menos 2 versiones del guion

**Postcondiciones**: Script puede comunicar cambios a departamentos mediante RF-024 (Comunicados) adjuntando Reporte de Cambios

**Actores**:

- Script (Continuista)
- Primera Ayudante de Dirección

**Dependencias**:
- RF-026 (Múltiples versiones de guion deben existir)
- Librería de OCR/extracción de texto: PyPDF2, pdfplumber
- Algoritmo diff: difflib (Python estándar)
