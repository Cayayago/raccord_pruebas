# HU-008 — Gestión de Perfil de Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-008 |
| Título | Gestión de Perfil de Usuario |
| Prioridad | Media |
| Estado | Completado |
| RF asociado | RF-008 |

---

## Historia

*Como* usuario registrado,
*quiero* actualizar mis datos de contacto, foto de perfil y preferencias de notificación,
*para* mantener mi información al día y personalizar mi experiencia en la plataforma.

## Criterios de Aceptación

- El usuario puede modificar teléfono, foto de perfil, preferencias de notificación y modo oscuro.
- Los campos críticos (email, nombre, apellido, departamento, rol, proyectos) solo los modifica un Administrador Total.
- La foto de perfil se valida en formato y tamaño (JPG/PNG, máx 2 MB) y se comprime antes de almacenarse.
- Los cambios se sincronizan automáticamente en todos los dispositivos del usuario.
