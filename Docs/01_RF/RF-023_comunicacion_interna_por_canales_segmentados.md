# RF-023 — Comunicación Interna por Canales Segmentados

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-023 |
| Título | Comunicación Interna por Canales Segmentados |
| Módulo | Gestión de Calendario y Planeación |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | RNF-020 |

---

**Descripción**: El sistema debe permitir enviar y recibir mensajes mediante canales segmentados (General, por Departamento, por Escena, por Personaje, Mensajes Directos) con adjuntos y priorización.


**Entradas**:

- Canal de comunicación (selección única):

        Canal General (todo el equipo)
        Canal por Departamento (Vestuario/Maquillaje/Utilería/Fotografía/Dirección/Producción)
        Canal por Escena (específico de una escena en rodaje)
        Canal por Personaje (todo relacionado a un personaje)
        Mensaje Directo (usuario a usuario)
- Contenido del mensaje (texto, máx 2000 caracteres)
        Adjuntos (opcionales):
            Fotografías desde galería de continuidad (selección desde RF-010)
            Fotografías nuevas (carga directa, máx 5 MB)
            Documentos PDF (máx 10 MB)

- Nivel de prioridad (selección única): Normal / Urgente

**Proceso**:

- Validar que usuario esté autenticado
- Validar que usuario tenga acceso al canal seleccionado según su rol:

Canal General: todos los usuarios
Canal por Departamento: solo usuarios de ese departamento + Script + Dirección + Administrador Total
Canal por Escena: usuarios involucrados en esa escena + Script + Primera AD + Dirección
Canal por Personaje: actores del personaje + Script + Jefes de Departamento + Dirección
Mensaje Directo: emisor y receptor únicamente


- Validar formato y tamaño de adjuntos
- Si adjunto es fotografía de continuidad: vincular referencia (no duplicar archivo)
- Si adjunto es fotografía nueva: almacenar en storage y aplicar marca de agua
- Crear mensaje en base de datos vinculado al canal
- Enviar notificación push a usuarios del canal:

        Normal: notificación estándar sin sonido (solo badge)
        Urgente: notificación con color rojo, sonido y badge
- Mostrar mensaje inmediatamente en chat del canal para usuarios online
- Permitir búsqueda histórica de mensajes por:

        Canal
        Palabra clave en contenido
        Usuario emisor
        Rango de fechas
- Mostrar confirmación de lectura (checkmarks):

        1 check: mensaje enviado
        2 checks: mensaje leído por todos los destinatarios

**Salidas**:

- Mensaje creado en base de datos
- Mensaje visible en canal correspondiente
- Notificaciones push enviadas a usuarios del canal
- Adjuntos almacenados o vinculados
- Confirmaciones de lectura visibles para emisor

**Precondiciones**:

- Usuario debe estar autenticado
- Usuario debe tener acceso al canal según su rol
- Canal debe existir (canales por Escena/Personaje se crean automáticamente)

**Postcondiciones**:

- Mensaje disponible para búsqueda histórica
- Usuarios del canal reciben notificación si están offline

**Actores**: Todos los usuarios del sistema (según permisos de canal)

**Dependencias**:

- RF-003 (Usuario autenticado)
- RF-005 (Sistema de roles)
- RF-022 (Notificaciones push)
- RF-010 (Adjuntar fotografías desde galería)
