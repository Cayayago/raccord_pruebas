# RNF-030 — Modularidad del Código

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-030 |
| Título | Modularidad del Código |
| Categoría | Mantenibilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe estructurarse en módulos independientes con interfaces bien definidas, permitiendo modificación o reemplazo de módulos individuales sin afectar el resto del sistema.

**Métrica**:
- Arquitectura modular con 5+ módulos independientes:

        Módulo de Autenticación
        Módulo de Continuidad Visual
        Módulo de Calendario
        Módulo de Guiones
        Módulo de Notificaciones
- Interfaces bien definidas (APIs internas)
- Acoplamiento bajo (Low Coupling)
- Cohesión alta (High Cohesion)
- Posibilidad de modificar módulo sin afectar otros


**Aplica a**:

- Código backend (Python)
- Código frontend (Flutter/Dart)

**Estándar/Norma**:
- ISO/IEC 25010 - Mantenibilidad
- Clean Architecture principles

**Método de Verificación**:

- Revisión de arquitectura del código
- Análisis de dependencias entre módulos
- Prueba: modificar un módulo (p. ej. Continuidad Visual) sin afectar el módulo de Autenticación
- Métricas de código: Coupling Between Objects (CBO), Lack of Cohesion (LCOM)
