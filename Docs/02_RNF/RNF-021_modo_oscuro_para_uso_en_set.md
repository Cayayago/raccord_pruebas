# RNF-021 — Modo Oscuro para Uso en Set

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-021 |
| Título | Modo Oscuro para Uso en Set |
| Categoría | Usabilidad / Accesibilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe proveer modo oscuro completo optimizado para uso en sets con poca luz, cumpliendo ratios de contraste WCAG 2.1 nivel AA y permitiendo al usuario alternar entre modo claro y oscuro.

**Métrica**:
- Modo oscuro disponible en 100% de pantallas
- Ratio de contraste texto/fondo ≥ 4.5:1 (WCAG 2.1 AA para texto normal)
- Ratio de contraste texto/fondo ≥ 7:1 (WCAG 2.1 AAA deseable)
- Alternancia entre modos en <1 segundo
- Preferencia guardada por usuario (persistente entre sesiones)


**Aplica a**:
Aplicación Flutter (iOS, Android, Windows, macOS)
Página web de ingreso
Todas las pantallas del sistema

**Estándar/Norma**:
- ISO 9241-11 - Usabilidad

**Método de Verificación**:
- Validación con herramientas de accesibilidad (WAVE, Lighthouse, Contrast Checker)
- Verificar contraste en todas las pantallas principales
- Pruebas en condiciones de baja luminosidad (simular set)
- Verificar legibilidad con 5 usuarios
