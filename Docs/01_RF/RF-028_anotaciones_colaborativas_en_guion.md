# RF-028 — Anotaciones Colaborativas en Guion

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-028 |
| Título | Anotaciones Colaborativas en Guion |
| Módulo | Gestión de Guiones |
| Prioridad | Alta |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir tres tipos de anotaciones en guiones PDF: personales (solo usuario), departamentales (equipo del departamento) y generales (todos los roles), con sincronización entre dispositivos.


**Entradas**:
- Guion abierto en visor (RF-027)
- Página y posición donde se crea anotación
- Tipo de anotación (selección única):

        Nota (comentario de texto)
        Resaltado (color de fondo sobre texto)
        Marcador (bookmark de página)

- Contenido de anotación (texto, máx 500 caracteres, si es nota)
- Nivel de visibilidad (selección única):

        Personal (solo yo)
        Departamental (mi departamento)
        General (todos)

**Proceso**:

- Validar que usuario esté visualizando guion (RF-027)
- Usuario selecciona texto o hace clic en página para crear anotación
- Mostrar menú contextual con opciones: Nota / Resaltado / Marcador
- Si elige Nota o Resaltado: solicitar contenido/color
- Solicitar nivel de visibilidad:

        Personal: siempre disponible para cualquier usuario
        Departamental: solo Jefes de Departamento pueden crear anotaciones departamentales
        General: solo Script puede crear anotaciones generales
- Crear anotación en base de datos con:

        ID de guion y versión
        Página y coordenadas (posición exacta)
        Tipo de anotación
        Contenido
        Nivel de visibilidad
        Autor
        Timestamp de creación

- Renderizar anotación superpuesta en el visor PDF:

        Personal: icono verde (solo visible para creador)
        Departamental: icono azul (visible para equipo del departamento)
        General: icono rojo (visible para todos)
- Sincronizar anotaciones entre todos los dispositivos del usuario
- Si usuario con rol Talento: solo puede crear anotaciones personales y solo en sus escenas asignadas
- Permitir editar y eliminar anotaciones propias
- Anotaciones de otros usuarios son solo lectura

**Salidas**:
- Anotación creada en base de datos
- Anotación visible en visor según nivel de visibilidad
- Sincronización automática entre dispositivos del usuario
- Notificación a equipo de departamento (si anotación departamental)

**Precondiciones**:
- Usuario debe estar visualizando guion (RF-027)
- Usuario debe tener permiso para crear anotaciones según su rol

**Postcondiciones**:
- Anotación disponible en todas las visualizaciones futuras del guion
- Anotaciones sincronizadas entre dispositivos

**Actores**: Todos los usuarios autorizados (con restricciones según rol)

**Dependencias**:

- RF-027 (Visualización de guion)
- RF-028 (Sistema de roles controla qué anotaciones puede crear cada rol)
