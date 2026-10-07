# RF-033 — Informe de Continuidad por Escena

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-033 |
| Título | Informe de Continuidad por Escena |
| Módulo | Reportes y Analítica |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe generar documento PDF con todas las fotografías de continuidad de una escena específica, organizadas por toma y personaje, con metadatos completos y comentarios.


**Entradas**:
- Número de escena (selección única)
- Filtros opcionales: Personaje específico, Tipo de Detalle

**Proceso**:
- Validar que usuario sea Script, Jefe de Departamento, Primera AD o Administrador Total
- Consultar todas las fotografías de la escena desde base de datos (RF-010)
- Aplicar filtros si usuario los especificó
- Organizar fotografías por:

        Toma (orden ascendente)
        Personaje (alfabético)
        Tipo de Detalle (Vestuario, Maquillaje, Utilería, Set)
- Generar PDF con estructura:

**Portada**:
- Proyecto
- Número de escena y descripción (desde RF-020 si existe)
- Fecha de generación del reporte
- Usuario que generó el reporte
- Contenido por toma:

        Número de Toma
        Fotografías de la toma (3-4 por página, tamaño adecuado)
- Debajo de cada fotografía:

        Nomenclatura completa
        Personaje(s)
        Tipo de Detalle
        Estado de Continuidad
        Fecha de rodaje
        Comentarios

- Historial de versiones:

        Si existen múltiples versiones de una misma fotografía, incluir comparación V1 vs V2 vs V3

- Aplicar marca de agua reforzada en cada página:

        Usuario que generó reporte
        Timestamp de generación
        Proyecto
        Marca múltiple en diagonal


- Comprimir PDF si supera 50 MB (mantener calidad de imágenes)
- Registrar generación de reporte en log de auditoría

**Salidas**:
- PDF con todas las fotografías de la escena organizadas
- Metadatos completos por fotografía
- Historial de versiones (si aplica)
- Marca de agua reforzada en cada página
- Registro en log de auditoría

**Precondiciones**:
- Usuario debe tener permiso según su rol
- Escena debe tener al menos 1 fotografía cargada

**Postcondiciones**:
- Reporte disponible para revisión antes de rodar escenas relacionadas o retomas
- Exportación queda registrada en auditoría

**Actores**: Script, Jefes de Departamento, Primera AD, Administrador Total

**Dependencias**:
- RF-010 (Fotografías de continuidad)
- RF-012 (Búsqueda de fotografías)
- RF-015 (Marca de agua)
- RF-009 (Log de auditoría)
