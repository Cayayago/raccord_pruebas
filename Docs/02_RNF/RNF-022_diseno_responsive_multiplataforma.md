# RNF-022 — Diseño Responsive Multiplataforma

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-022 |
| Título | Diseño Responsive Multiplataforma |
| Categoría | Usabilidad / Compatibilidad |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe funcionar sin degradación de funcionalidad en tablets (prioridad), smartphones y desktop, con diseño responsive que se adapta automáticamente a diferentes tamaños de pantalla.

**Métrica**:
- Funcionalidad 100% en:

        Tablets: iPad Pro 12.9", iPad Air, Samsung Galaxy Tab (768px - 1024px ancho)
        Smartphones: iPhone 12+, Samsung Galaxy S20+ (360px - 414px ancho)
        Desktop: 1366x768 (mínimo), 1920x1080 (recomendado)
- Elementos de interfaz escalables sin scroll horizontal
- Imágenes responsive (tamaños adaptativos)
- Botones táctiles ≥ 44x44px (iOS HIG)
- Texto legible sin zoom (mínimo 16px en móvil)


**Aplica a**:

- Aplicación Flutter multiplataforma (iOS, Android, Windows, macOS), con layouts adaptativos según tamaño de pantalla
- Página web de ingreso (autenticación) — solo necesita adaptarse a desktop, ya que en tablet/celular el enlace abre la app nativa directamente (ver ADR de stack de frontend)

**Estándar/Norma**:

- iOS Human Interface Guidelines
- Material Design Guidelines (Android)
- W3C Mobile Web Best Practices

**Método de Verificación**:
- Verificar funcionalidad completa en cada dispositivo
- Verificar sin scroll horizontal
- Verificar botones tocables (44x44px mínimo)
