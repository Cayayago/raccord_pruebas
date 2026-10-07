# RF-036 — Checklist de Escenas Grabadas vs Pendientes

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-036 |
| Título | Checklist de Escenas Grabadas vs Pendientes |
| Módulo | Reportes y Analítica |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**:El sistema debe mostrar lista visual de todas las escenas del proyecto con indicadores de estado (completadas, en progreso, pendientes), permitiendo filtrado por episodio, locación, personaje y fecha.


**Entradas**:

- Proyecto activo
- Filtros opcionales: Episodio, Locación, Personaje, Rango de fechas

**Proceso**:

- Validar que usuario esté autenticado
- Consultar todas las escenas del proyecto desde:

        Desgloses de escenas (RF-020)
        Calendario de rodaje (RF-018): escenas programadas
        Parte de rodaje (RF-034): escenas efectivamente rodadas


- Calcular estado de cada escena:

        Completada: Escena marcada como rodada en parte de rodaje Y tiene fotografías de continuidad con estado OK
        En Progreso: Escena tiene fotografías pero no marcada como completada
        Pendiente: Escena sin fotografías y no rodada
        Programada: Escena tiene fecha en calendario pero no rodada aún


- Mostrar lista visual:

        Vista de tabla o cards
        Indicador visual de estado (color + icono)
- Información por escena:

        Número de escena
        Descripción breve
        Estado
        Fecha programada (si existe)
        Fecha rodada (si completada)
        Personajes involucrados
        Locación
        Progreso de continuidad (% de fotografías OK)


- Permitir filtros múltiples:

        Por episodio (si es serie)
        Por locación (agrupar escenas de misma locación)
        Por personaje (escenas donde aparece personaje X)
        Por rango de fechas (programadas o rodadas)
        Por estado (solo completadas, solo pendientes, etc.)


- Mostrar estadísticas generales:

        Total de escenas: X
        Completadas: Y (Z%)
        En progreso: W
        Pendientes: V
        Días de rodaje transcurridos vs estimados


- Permitir exportar checklist en PDF o Excel

**Salidas**:

- Lista visual de escenas con estados
- Estadísticas de progreso del proyecto
- Exportación en PDF/Excel

**Precondiciones**:

- Proyecto debe estar activo
- Debe existir al menos 1 escena (RF-020)

**Postcondiciones**:

- Equipo puede visualizar evolución del proyecto
- Identificar escenas pendientes para coordinación

**Actores**: Todos los usuarios autorizados (visibilidad según rol)

**Dependencias**:

- RF-020 (Desgloses de escenas)
- RF-018 (Calendario)
- RF-034 (Parte de rodaje marca escenas como completadas)
- RF-010 (Fotografías de continuidad)0
