# RF-032 — Reporte de Preparación para Rodaje

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-032 |
| Título | Reporte de Preparación para Rodaje |
| Módulo | Reportes y Analítica |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe generar checklist visual que muestre estado de preparación de una escena o episodio específico antes del rodaje, identificando por departamento qué está completo, incompleto o bloqueante.


**Entradas**:
- Escena(s) o episodio a consultar (selección única o múltiple)
- Fecha estimada de rodaje (opcional)

**Proceso**:
- Validar que usuario sea Script, Primera AD, Jefe de Departamento o Administrador Total
- Para cada escena seleccionada, consultar:

        Fotografías de continuidad subidas (RF-010)
        Estados de continuidad (RF-014): OK / Pendiente / Error
        Desglose de escena (RF-020): qué se requiere por departamento
- Calcular estado por departamento:

        Completo: Todas las fotografías requeridas están subidas y en estado OK
        Incompleto: Faltan fotografías de referencia
        Bloqueante: Existen errores críticos (estado "Error a Corregir") no resueltos
- Generar reporte visual:

        Encabezado: Escena(s), Episodio, Fecha de rodaje
        Tabla por departamento:
        DepartamentoEstadoFotografías OKFotografías PendientesErrores CríticosResponsable

- Sección "Fotografías Faltantes":

        Personaje: [Nombre]
        Detalle: [Vestuario/Maquillaje/Utilería]
        Descripción: [Qué falta específicamente]

- Sección "Errores Críticos Pendientes":

        Departamento
        Descripción del error
        Fotografía involucrada (thumbnail)
        Responsable de resolver
- Permitir exportar reporte en PDF con marca de agua
- Mostrar indicador visual general:

        Verde: Todo listo para rodar
        Amarillo: Listo con observaciones menores
        Rojo: NO listo, existen bloqueantes

**Salidas**:
- Reporte visual de preparación por departamento
- Lista de fotografías faltantes
- Lista de errores críticos pendientes
- Exportación en PDF con marca de agua

**Precondiciones**:
- Escena(s) debe(n) existir en el proyecto
- Debe existir desglose de escena (RF-020) para saber qué se requiere

**Postcondiciones**:
- Equipo puede identificar qué falta antes de rodar
- Prevención de retrasos en set por falta de preparación

**Actores**: Script, Primera AD, Jefes de Departamento, Administrador Total

**Dependencias**:
- RF-010 (Fotografías de continuidad)
- RF-014 (Estados de continuidad)
- RF-020 (Desgloses de escenas)
