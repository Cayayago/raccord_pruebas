# HU-014 — Marca de Agua Dinámica No Removible

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-015 |
| Título | Marca de Agua Dinámica No Removible |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociado | RF-015 |

---

## Historia

*Como* Productor de Línea,
*quiero* que toda fotografía o guion visualizado lleve una marca de agua con el usuario y la fecha,
*para* proteger el material confidencial de la producción y poder rastrear cualquier filtración.

## Criterios de Aceptación

- La marca de agua se aplica en tiempo real sobre la visualización, sin modificar el archivo original almacenado.
- La marca incluye nombre del usuario, timestamp y proyecto, en posición aleatoria y semi-transparente.
- En móviles se bloquean las capturas de pantalla; en la web se deshabilitan el clic derecho y los atajos de captura/impresión.
- Cada visualización queda registrada en el log de auditoría.
