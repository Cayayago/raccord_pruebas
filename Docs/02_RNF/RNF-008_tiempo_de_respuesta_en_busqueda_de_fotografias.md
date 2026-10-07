# RNF-008 — Tiempo de Respuesta en Búsqueda de Fotografías

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-008 |
| Título | Tiempo de Respuesta en Búsqueda de Fotografías |
| Categoría | Rendimiento |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-012 |

---

**Descripción**: El sistema debe responder consultas de búsqueda de fotografías en menos de 10 segundos (percentil 95) incluso con bases de datos de más de 10,000 fotografías y múltiples filtros combinados.

**Métrica**:
- Tiempo de respuesta < 10 segundos (p95)
- Tiempo de respuesta promedio < 5 segundos
- Con base de datos de 10,000+ fotografías
- Con 5+ filtros combinados
- Con 20 usuarios simultáneos ejecutando búsquedas


**Aplica a**: RF-012 (Búsqueda Avanzada por Múltiples Criterios)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:

- Base de datos de prueba con 15,000 fotografías
- Apache JMeter simulando 20 usuarios concurrentes
- Búsquedas con 5 filtros combinados
- Ejecutar durante 30 minutos
- Verificar p95 < 10 segundos

**Fuente**:

- Objetivo Específico 1 (<10 segundos)
- Descripción del Problema (búsqueda manual actual: 5-10 minutos)
