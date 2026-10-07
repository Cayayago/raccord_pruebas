# RNF-018 — Marca de Agua Personalizada e Irreemplazable

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-018 |
| Título | Marca de Agua Personalizada e Irreemplazable |
| Categoría | Seguridad / Funcionalidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-010, RF-015, RF-027 |

---

**Descripción**: El sistema debe aplicar marca de agua dinámica semi-transparente en posición aleatoria sobre fotografías y guiones visualizados, sin modificar archivo original, imposibilitando eliminación fácil.

**Métrica**:
- 100% de visualizaciones con marca de agua
- Marca incluye:

        Nombre completo del usuario
        Timestamp de visualización
        Nombre del proyecto
- Características técnicas:

        Opacidad: 30-40%
        Posición: aleatoria (diferente cada visualización)
        Se repite múltiples veces en diagonal
        Color: blanco con borde negro (legible sobre cualquier fondo)
        Fuente: Sans-serif, 14-16px
- Archivo original sin marca permanece intacto en storage


**Aplica a**:

- RF-015 (Marca de agua dinámica)
- RF-010 (Visualización de fotografías)
- RF-027 (Visualización de guiones)

**Estándar/Norma**: ISO/IEC 27001

**Método de Verificación**:
- Visualizar 50 fotografías por mismo usuario
- Verificar marca de agua presente en todas
- Verificar posición diferente en cada visualización
- Verificar archivo original descargado (por admin) NO tiene marca
- Intentar eliminar marca con herramientas básicas de edición (debe ser difícil)
