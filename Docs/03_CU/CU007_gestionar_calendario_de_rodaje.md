# CU007 — Gestionar Calendario de Rodaje

## Identificación

| Campo | Valor |
|---|---|
| ID | CU007 |
| Título | Gestionar Calendario de Rodaje |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Administrador y sub - admi |
| Frecuencia | Media |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador y sub - admi
- **Secundario:** Jefes de Departamento, Sistema notificaciones (CU008), Sistema desgloses (CU009), Sistema LOG

#### Descripción

Permite a la Primera Ayudante de Dirección crear, modificar y eliminar eventos en el calendario centralizado. Cada evento representa una jornada de rodaje e incluye varios campos obligatorios: Fecha, Escenas a grabar (múltiples), Locación, Personajes presentes, Hora ficticia (día/tarde/noche), Páginas de guion, Equipo técnico requerido, Vestuario específico por personaje, Maquillaje especial, Utilería clave, Notas de dirección, y Estado (Confirmado/Tentativo/Cancelado). Los Jefes de Departamento pueden añadir notas específicas a su área. El calendario tiene vista diaria, semanal y mensual. Todos los usuarios pueden visualizar el calendario.

#### Precondiciones

- Ejecutor Primera AD o Administrador Total autenticado
- Proyecto activo seleccionado
- Escenas y personajes registrados en BD
- Para modificar: evento existe, no cancelado definitivamente

#### Postcondiciones

**Creación:**
- Evento en BD con campos ya definidos.
- UUID generado
- Desgloses vinculados automáticamente
- Usuarios afectados calculados (personajes+deptos+Script+AD)
- Visible en vistas (diaria/semanal/mensual)
- Notificaciones enviadas (CU008)
- Registro en LOG

**Modificación:**
- Campos actualizados
- Cambios críticos identificados (Fecha/Escenas/Locación/Personajes)
- Historial en BD
- Usuarios recalculados
- Notificaciones según prioridad
- Registro en LOG

**Nota Jefe Depto:**
- Guardada en BD vinculada a evento
- Visible en sección departamento
- Notificación a Primera AD
- Registro en LOG

**Cancelación:**
- Marcado "Cancelado"
- Notificación crítica a todos afectados
- Movido a "Eventos Cancelados"
- Registro en LOG

**Visualización:**
- Talento ve solo sus eventos (filtro auto)
- Eventos coloreados (Confirmado:verde, Tentativo:amarillo, Cancelado:rojo)

#### Flujo Principal (Crear)

1. Primera AD abre "Calendario"
2. Primera AD hace clic "Nuevo Evento"
3. Sistema muestra formulario con campos obligatorios
4. Primera AD completa: Fecha, Escenas, Locación, Personajes, Hora ficticia, Páginas guion, Equipo técnico, Vestuario, Maquillaje, Utilería, Notas dirección, Estado
5. Sistema valida campos completos
6. Sistema genera UUID para evento
7. Si escenas tienen desgloses: sistema vincula información automáticamente
8. Sistema calcula usuarios afectados (personajes + deptos + Script + AD)
9. Sistema crea evento en BD
10. Sistema envía notificaciones push a usuarios afectados (CU008)
11. Sistema muestra evento en vistas: diaria, semanal, mensual
12. Sistema registra creación en LOG

#### Flujo Principal (Modificar)

1. Primera AD selecciona evento de calendario
2. Primera AD hace clic "Editar"
3. Primera AD modifica campos deseados
4. Sistema detecta qué campos cambiaron
5. Sistema identifica cambios críticos (Fecha/Escenas/Locación/Personajes)
6. Sistema guarda cambios en BD + historial
7. Sistema recalcula usuarios afectados
8. Sistema envía notificaciones según prioridad del cambio
9. Sistema registra modificación en LOG

#### Flujos Alternativos

**FA-001: Duplicar Evento Existente** : Primera AD selecciona evento → "Duplicar" → Sistema copia campos → Primera AD modifica fecha y personajes → Sistema crea nuevo evento

**FA-002: Exportar Calendario a PDF/Excel** : Primera AD selecciona rango fechas → "Exportar" → Sistema genera documento con eventos → Descarga con marca de agua

#### Flujos Excepcionales

**FE-001: Conflicto de Locación** : Sistema detecta locación ya usada mismo día/hora → Alerta "Conflicto detectado" → Primera AD confirma o cambia locación

#### Frecuencia

Media
