# RF-018 — Creación de Eventos en Calendario de Rodaje

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-018 |
| Título | Creación de Eventos en Calendario de Rodaje |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-010, RNF-020 |

---

**Descripción**: El sistema debe permitir a la Primera Ayudante de Dirección crear eventos en calendario centralizado con 12 campos obligatorios que definen cada jornada de rodaje.


**Entradas**:

- Fecha de rodaje (fecha única)
- Escenas a grabar (selección múltiple de escenas del proyecto)
- Locación (texto, máx 200 caracteres)
- Personajes presentes (selección múltiple de personajes del proyecto)
- Hora ficticia (selección única): Día / Tarde / Noche / Amanecer / Atardecer
- Páginas de guion (texto, ej: "15-23")
- Equipo técnico requerido (texto libre, máx 300 caracteres)
- Vestuario específico por personaje (texto libre, máx 500 caracteres)
- Maquillaje especial requerido (texto libre, máx 300 caracteres)
- Utilería clave (objetos hero) (texto libre, máx 300 caracteres)
- Notas de dirección (texto libre, máx 500 caracteres)
- Estado (selección única): Confirmado / Tentativo / Cancelado

**Proceso**:

- Validar que usuario sea Primera Ayudante de Dirección o Administrador Total
- Validar que todos los 12 campos obligatorios estén completos
- Validar que fecha no esté en el pasado (advertencia, no bloqueo)
- Crear evento en base de datos vinculado al proyecto
- Si escenas seleccionadas tienen desgloses (RF-020): vincular automáticamente información del desglose
- Calcular automáticamente usuarios afectados:

        Todos los usuarios cuyos personajes están involucrados
        Jefes de departamentos mencionados (Vestuario, Maquillaje, Utilería)
        Script siempre incluido

- Evento visible inmediatamente en calendario (vistas diaria/semanal/mensual)
- Enviar notificaciones push a usuarios afectados
- Registrar creación en log de auditoría

**Salidas**:
- Evento creado en calendario
- Notificaciones push enviadas a usuarios afectados
- Registro en log de auditoría

**Precondiciones**:
- Usuario debe ser Primera AD o Administrador Total
- Proyecto debe estar activo
- Escenas y personajes deben estar previamente registrados

**Postcondiciones**:
- Evento visible en calendario para usuarios autorizados
- Usuarios afectados reciben notificación instantánea

**Actores**:
- Primera Ayudante de Dirección
- Administrador Total (también puede crear eventos)

**Dependencias**:
- RF-017 (Proyecto debe existir)
- RF-009 (Log de auditoría)
