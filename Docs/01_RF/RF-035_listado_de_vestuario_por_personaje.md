# RF-035 — Listado de Vestuario por Personaje

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-035 |
| Título | Listado de Vestuario por Personaje |
| Módulo | Reportes y Analítica |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir al Jefe de Vestuario generar informe visual de inventario de vestuario por personaje con fotografías, descripciones, escenas donde se usa y estados de las prendas.

**Entradas**:
- Personaje seleccionado (selección única)
- Filtros opcionales: Tipo de prenda, Estado (limpio/sucio/roto)

**Proceso**:

- Validar que usuario sea Jefe de Vestuario, Script o Administrador Total
- Consultar todas las fotografías de continuidad con:

        Personaje = personaje seleccionado
        Tipo de Detalle = Vestuario


- Aplicar filtros si usuario los especificó
        Organizar fotografías por:

            Orden cronológico de escenas (Escena 1, Escena 2, etc.)
            Estado de la prenda (si existen múltiples copias)


- Extraer metadatos de cada fotografía:

        Descripción de la prenda (desde comentarios)
        Escena donde se usa
        Estado de la prenda (limpio/sucio/roto/mojado)
        Fecha de rodaje
        Notas de vestuario (desde RF-020: Desgloses)


- Generar reporte visual:

        Portada:

            Proyecto
            Personaje
            Total de prendas inventariadas
            Fecha de generación


        Contenido:

            Tabla con fotografía + descripción por prenda:
            FotografíaDescripciónEscenasEstado(s)Notas

- Sección de tracking:

        Cronología de uso: cuándo se usó cada prenda en orden de escenas
        Estados por escena: Escena 1 (limpio), Escena 5 (sucio), Escena 8 (roto)

- Notas de mantenimiento:

        Prendas que requieren lavandería
        Prendas que requieren reparación
        Prendas que requieren duplicados adicionales


- Aplicar marca de agua
- Permitir exportar en PDF o Excel

**Salidas**:
- Informe visual de inventario de vestuario por personaje
- Cronología de uso por escena
- Notas de mantenimiento
- Exportación en PDF o Excel con marca de agua

**Precondiciones**:
- Debe existir al menos 1 fotografía de vestuario del personaje
- Usuario debe tener permiso según rol

**Postcondiciones**:
- Jefe de Vestuario tiene control visual completo del vestuario del personaje
- Planning de vestuario facilitado para fechas de rodaje

**Actores**:
- Jefe de Vestuario (principal usuario)
- Script, Administrador Total (también pueden generar)

**Dependencias**:
- RF-010 (Fotografías de continuidad con Detalle = Vestuario)
- RF-020 (Desgloses pueden incluir notas de vestuario)
