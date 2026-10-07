# CU010 — Comunicación Interna por Canales

## Identificación

| Campo | Valor |
|---|---|
| ID | CU010 |
| Título | Comunicación Interna por Canales |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Todos los usuarios |
| Frecuencia | Alta |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Todos los usuarios
- **Secundario:** Sistema canales, Sistema notificaciones, Sistema adjuntos (CU004), Sistema LOG

#### Descripción

Permite a todos los usuarios enviar y recibir mensajes mediante canales segmentados: Canal General (todo el equipo), Canales por Departamento, Canales por Escena, Canales por Personaje, y Mensajes Directos. Los mensajes pueden incluir texto, fotografías adjuntas desde la galería de continuidad, documentos PDF, y nivel de prioridad (Normal/Urgente). Los mensajes urgentes se destacan con color rojo y generan notificación push inmediata. El sistema permite búsqueda histórica de mensajes. Los mensajes tienen confirmación de lectura visible para el emisor.

#### Precondiciones

- Usuario autenticado con acceso al canal (validación RBAC)
- Canal existe (canales Escena/Personaje auto-creados)
- Adjunto foto: existe en sistema; PDF: ≤10 MB

#### Postcondiciones

**Envío:**
- Validación acceso ejecutada
  - General: todos
  - Depto: usuarios depto + Script + Dir+Admin
  - Escena: involucrados + Script + AD + Dir
  - Personaje: actores + Script + Jefes + Dir
  - Directo: emisor + receptor
- Mensaje en BD
- Adjuntos vinculados (foto:referencia no duplica, nueva:carga+marca agua, PDF:validado)
- Visible inmediato online
- Notificación push offline (Normal:badge solo, Urgente:rojo+sonido+vibra)
- Checkmarks (✓:enviado, ✓✓:leído todos)
- Registro en LOG

**Búsqueda histórica:**
- Filtros (canal/keyword/emisor/fecha)
- Full-text search
- Orden cronológico inverso
- Keyword resaltado
- Paginación 50/página
- Click→scroll auto

**Confirmaciones lectura:**
- Modal con lista destinatarios (✓✓Leído+timestamp, ✓Entregado)
- % lectura mostrado

#### Flujo Principal

1. Usuario abre canal deseado (General/Departamento/Escena/Personaje/Directo)
2. Sistema valida acceso del usuario al canal (RBAC)
3. Usuario escribe mensaje (máx 2000 caracteres)
4. Usuario opcionalmente adjunta: foto desde galería, foto nueva, PDF
5. Usuario selecciona prioridad: Normal / Urgente
6. Usuario hace clic "Enviar"
7. Sistema valida adjuntos (foto existe o PDF ≤10MB)
8. Sistema crea mensaje en BD
9. Sistema vincula adjuntos (foto: referencia, nueva: sube+marca agua, PDF: valida)
10. Sistema muestra mensaje inmediatamente para usuarios online
11. Sistema envía notificación push a usuarios offline
12. Sistema implementa confirmación de lectura (✓ enviado, ✓✓ leído todos)
13. Sistema registra envío en LOG

#### Flujos Alternativos

**FA-001: Responder Mensaje Específico (Thread)** : Usuario selecciona mensaje → "Responder" → Mensaje vinculado como respuesta → Mostrado anidado con línea de conexión

**FA-002: Mencionar Usuario (@nombre)** : Usuario escribe @nombre → Autocompletado → Sistema notifica usuario mencionado → Mensaje destacado para mencionado

**FA-003: Fijar Mensaje Importante** : Jefe Depto fija mensaje en canal → Permanece arriba → Visible con icono 📌 → Todos pueden ver hasta des-fijar

#### Flujos Excepcionales

**FE-001: PDF Excede 10MB** : Sistema detecta tamaño → Rechaza adjunto → Muestra "PDF muy grande, máx 10MB" → Sugiere comprimir o usar enlace externo

**FE-002: Usuario Sin Acceso a Canal** : Usuario intenta acceder canal restringido → Sistema valida RBAC → Bloquea acceso → Muestra "No tienes permisos para este canal"

#### Frecuencia

Alta
