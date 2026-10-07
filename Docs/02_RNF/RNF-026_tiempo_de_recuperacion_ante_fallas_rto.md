# RNF-026 — Tiempo de Recuperación ante Fallas (RTO)

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-026 |
| Título | Tiempo de Recuperación ante Fallas (RTO) |
| Categoría | Confiabilidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe restaurar información completa en menos de 10 minutos tras falla crítica (Recovery Time Objective), con máximo tolerable de 30 minutos en escenarios complejos.

**Métrica**:
- RTO objetivo: < 10 minutos
- RTO máximo tolerable: < 30 minutos
- Escenarios cubiertos:

        Falla de servidor (cambio a servidor backup)
        Corrupción de base de datos (restauración desde backup)
        Pérdida de datos (restauración desde backup más reciente)
- RPO (Recovery Point Objective): < 1 hora (pérdida máxima de datos = última hora)

**Aplica a**:
- Infraestructura completa del sistema
- Base de datos
- Storage

**Estándar/Norma**:
- ISO/IEC 27031 - Business Continuity
- ISO/IEC 22301 - Disaster Recovery

**Método de Verificación**:
- Simulaciones de desastre (Disaster Recovery Drills):

        Simular caída de servidor principal
        Simular corrupción de base de datos
        Simular pérdida de archivos en storage
- Medir tiempo desde detección de falla hasta sistema 100% operativo
- Realizar 5 simulaciones diferentes
- Verificar promedio < 10 minutos
