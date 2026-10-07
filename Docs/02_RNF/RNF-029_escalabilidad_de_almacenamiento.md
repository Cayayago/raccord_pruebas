# RNF-029 — Escalabilidad de Almacenamiento

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-029 |
| Título | Escalabilidad de Almacenamiento |
| Categoría | Escalabilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe soportar almacenamiento inicial de 100 GB (15,000-20,000 fotografías) con capacidad de expansión sin downtime ni migración manual de datos hasta varios TB.

**Métrica**:
- Capacidad inicial: 100 GB
- Expansión sin downtime
- Expansión sin migración manual
- Escalable hasta varios TB (5-10 TB)
- Uso de storage cloud con auto-scaling (S3, Azure Blob, etc.)


**Aplica a**:

- Storage de fotografías
- Storage de guiones
- Storage de documentos adjuntos

**Estándar/Norma**: ISO/IEC 25010 - Capacidad

**Método de Verificación**:

- Configurar storage con S3 Standard (auto-scaling)
- Simular carga de 100 GB de fotografías
- Verificar performance sin degradación
- Añadir 50 GB adicionales sin downtime
- Verificar expansión automática sin intervención
