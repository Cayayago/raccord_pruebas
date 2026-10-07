# CU015 — Comparar Versiones de Guion

## Identificación

| Campo | Valor |
|---|---|
| ID | CU015 |
| Título | Comparar Versiones de Guion |
| Módulo | Módulo 4: Gestión de Guiones |
| Actor primario | Administrador, sub-admi y onset |
| Frecuencia | Baja |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador, sub-admi y onset
- **Secundario:** Sistema extracción PDF, Algoritmo diff, Sistema reportes, Sistema LOG

#### Descripción

Permite al Script y Primera AD visualizar diferencias entre dos versiones del guion mediante comparación visual lado a lado (diff). El sistema resalta en colores: texto eliminado (rojo), texto nuevo (verde), texto modificado (amarillo). El Script puede generar un "Reporte de Cambios" en PDF que lista todas las diferencias entre versiones, útil para comunicar actualizaciones a los departamentos.

#### Precondiciones

- Ejecutor Script o Primera AD autenticado
- ≥2 versiones guion en sistema
- PDFs con texto extraíble (no escaneos imagen)

#### Postcondiciones

**Comparación:**
- Dos versiones seleccionadas (ej v1.0→v2.0)
- PDFs cargados
- Texto extraído (PyPDF2/pdfplumber, OCR si necesario)
- Diff ejecutado (difflib línea×línea)
- Diferencias categorizadas (eliminado:rojo, nuevo:verde, modificado:amarillo, sin cambio:normal)
- Vista lado a lado (izq:v1.0, der:v2.0, scroll sincronizado)
- Índice cambios (páginas+cantidad+navegación rápida)
- Registro en LOG

**Reporte Cambios:**
- PDF generado con:
  - Portada (proyecto/comparación/fecha/usuario)
  - Resumen (total cambios/páginas/escenas nuevas/eliminadas)
  - Detalle tabla (Página|Línea|Cambio|Anterior|Nuevo)
- Marca de agua reforzada (usuario+timestamp+proyecto múltiple diagonal)
- Descargable
- Registro en LOG
- Compartible vía CU011/CU010

#### Flujo Principal (Comparar)

1. Script/Primera AD hace clic "Comparar Versiones"
2. Sistema muestra selector de versiones
3. Usuario selecciona versión antigua (ej: v1.0) y versión nueva (ej: v2.0)
4. Usuario hace clic "Comparar"
5. Sistema carga ambas versiones desde storage
6. Sistema extrae texto de PDFs (PyPDF2/pdfplumber)
7. Sistema ejecuta algoritmo diff (difflib línea por línea)
8. Sistema categoriza diferencias: eliminado (rojo), nuevo (verde), modificado (amarillo)
9. Sistema muestra vista lado a lado: izquierda (v1.0), derecha (v2.0)
10. Sistema sincroniza scroll entre columnas
11. Sistema genera índice de cambios (páginas + cantidad)
12. Sistema registra comparación en LOG

#### Flujo Principal (Generar Reporte)

1. Usuario hace clic "Generar Reporte de Cambios"
2. Sistema genera PDF con: Portada + Resumen + Detalle tabla (Página|Línea|Cambio|Anterior|Nuevo)
3. Sistema aplica marca de agua reforzada
4. Sistema permite descarga del PDF
5. Sistema registra generación en LOG

#### Flujos Alternativos

**FA-001: Comparar Versiones No Consecutivas** : Usuario selecciona v1.0 y v3.0 (saltando v2.0) → Sistema compara directamente → Muestra cambios acumulados

#### Flujos Excepcionales

**FE-001: PDF Sin Texto Extraíble (Escaneo)** : Sistema intenta extracción → Detecta imagen escaneada → Ejecuta OCR (Tesseract) → Si falla: muestra "No se puede comparar PDF escaneado"

**FE-002: Diferencias Excesivas (>80% cambios)** : Sistema calcula % cambios → Detecta >80% → Alerta "Guiones muy diferentes, considera versión nueva en lugar de comparación"

#### Frecuencia

Baja
