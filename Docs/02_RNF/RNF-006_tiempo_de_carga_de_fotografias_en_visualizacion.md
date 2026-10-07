# RNF-006 — Tiempo de Carga de Fotografías en Visualización

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-006 |
| Título | Tiempo de Carga de Fotografías en Visualización |
| Categoría | Rendimiento |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-010, RF-013 |

---

**Descripción**: El sistema debe cargar fotografías de alta resolución (3-6 MB) para visualización en menos de 5 segundos con conexión estándar (10 Mbps), aplicando marca de agua dinámica en tiempo real.

**Métrica**:
- Tiempo de carga completa < 5 segundos (percentil 95)
- Con fotografías de hasta 6 MB
- Con conexión de 10 Mbps (4G estándar)
- Incluye: descarga + aplicación de marca de agua + renderizado


**Aplica a**:
- RF-010 (Visualización de fotografías)
- RF-013 (Comparación lado a lado)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:

- Pruebas con throttling de red simulando 10 Mbps
- 50 fotografías de 6 MB cada una
- Medir tiempo desde click en fotografía hasta visualización completa
- Verificar p95 < 5 segundos

**Fuente**:
- Oscar: "Máximo 5 segundos"
- Objetivo Específico 1
