# RNF-007 — Tiempo de Subida de Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-007 |
| Título | Tiempo de Subida de Fotografías |
| Categoría | Rendimiento |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-010 |

---

**Descripción**: El sistema debe completar la subida de fotografías (incluyendo validación, procesamiento y confirmación) en menos de 5 segundos por fotografía con conexión estándar.

**Métrica**:

- Tiempo de subida < 5 segundos por fotografía (percentil 95)
- Con fotografías de hasta 10 MB
- Con conexión upload de 5 Mbps
- Incluye: subida + validación + generación nomenclatura + almacenamiento + confirmación


**Aplica a**: RF-010 (Carga de fotografías con metadatos)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:
- Pruebas con 100 fotografías de 6-10 MB
- Throttling de red simulando 5 Mbps upload
- Medir desde click "Subir" hasta mensaje "Fotografía subida exitosamente"
- Verificar p95 < 5 segundos

**Fuente**:
- Oscar: "Tiene que suceder al instante, máximo 5 segundos"
- Entrevista Oscar (tiempos vertiginosos)
