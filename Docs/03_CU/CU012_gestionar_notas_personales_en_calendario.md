# CU012 — Gestionar Notas Personales en Calendario

## Identificación

| Campo | Valor |
|---|---|
| ID | CU012 |
| Título | Gestionar Notas Personales en Calendario |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Cualquier usuario |
| Frecuencia | Media |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Cualquier usuario
- **Secundario:** Sistema calendario, Sistema cifrado

#### Descripción

Permite a cualquier usuario crear, modificar y eliminar notas personales privadas asociadas a cualquier día del calendario. Estas notas son completamente privadas y solo visibles para el usuario que las creó, sin importar su rol en el sistema. Las notas se muestran en el calendario con un icono distintivo (candado) visible solo para su creador. Estas notas NO son incluidas en reportes de producción ni son accesibles en auditorías, garantizando privacidad absoluta del usuario.

#### Precondiciones

- Usuario autenticado
- Fecha parte del calendario proyecto activo

#### Postcondiciones

**Creación:**
- Modal con formulario (contenido 1000 chars, tipo opcional:Recordatorio/Tarea/Observación/Idea)
- Nota en BD cifrada (AES-256 con clave única usuario)
- Flag privada=true
- Icono candado en fecha (solo visible para creador)
- NO en LOG

**Visualización:**
- Click en candado
- Contenido descifrado
- Modal con contenido+tipo
- Opciones Editar/Eliminar

**Modificación:**
- Contenido re-cifrado
- Timestamp actualizado
- NO en LOG

**Eliminación:**
- Confirmación requerida
- Nota borrada BD
- Icono removido
- NO en LOG

**Búsqueda:**
- Filtros (fecha/tipo/keyword)
- Resultados cronológicos
- Click→navega a fecha+abre nota

**Privacidad absoluta:**
- NO en reportes
- NO en LOG
- Admins NO ven
- NO en exportaciones
- Eliminadas automáticamente si usuario revocado

#### Flujo Principal

1. Usuario selecciona fecha en calendario
2. Usuario hace clic icono "Añadir Nota Personal"
3. Sistema muestra modal con formulario
4. Usuario ingresa contenido (máx 1000 chars) y tipo opcional (Recordatorio/Tarea/Observación/Idea)
5. Usuario hace clic "Guardar"
6. Sistema cifra contenido con AES-256 (clave única del usuario)
7. Sistema crea nota en BD con flag privada=true
8. Sistema muestra icono candado en fecha (solo visible para creador)
9. Nota NO se registra en LOG (privacidad absoluta)

#### Flujos Alternativos

**FA-001: Sincronización Multi-Dispositivo** : Usuario crea nota en móvil → Sistema sincroniza cifrada → Usuario abre tablet → Nota visible descifrada con misma clave

#### Frecuencia

Media
