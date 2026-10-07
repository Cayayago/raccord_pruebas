# RNF-009 — Volumen Diario de Fotografías Soportado

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-009 |
| Título | Volumen Diario de Fotografías Soportado |
| Categoría | Rendimiento / Escalabilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | RF-010 |

---

**Descripción**: El sistema debe soportar la carga diaria de 50-100 fotografías de alta resolución (total: 100-600 MB/día) sin degradación de rendimiento ni saturación de almacenamiento.

**Métrica**:
- Capacidad de subida: 100 fotografías/día sin problemas
- Tamaño promedio por fotografía: 2-6 MB
- Almacenamiento diario: hasta 600 MB
- Sin degradación de tiempos de respuesta tras acumulación de 10,000+ fotografías


**Aplica a**:
- RF-010 (Carga de fotografías)
- Sistema de almacenamiento (S3 o equivalente)

**Estándar/Norma**: ISO/IEC 25010 - Capacidad

**Método de Verificación**:

- Pruebas de carga durante 30 días consecutivos
- Subir 100 fotografías diarias
- Verificar tiempos de subida se mantienen constantes
- Verificar tiempos de búsqueda no se degradan

**Fuente**:

- Entrevistas Script, DoP, Jefe de Vestuario (50-100 fotos/día)
- Entrevista Oscar (fotografías en rodajes activos)
