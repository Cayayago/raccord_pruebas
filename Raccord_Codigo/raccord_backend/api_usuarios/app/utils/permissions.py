# ==========================================
# CATALOGO DE ROLES
# ==========================================
# Debe coincidir con la tabla "roles" (id_rol) de la base de datos.
ADMINISTRADOR = 1001
DIRECTOR = 1002
JEFE_DEPARTAMENTO = 1003
ONSET = 1004
USUARIO = 1005


# ==========================================
# MATRIZ DE PERMISOS POR ROL
# ==========================================
# Reglas acordadas:
#
# 1001 Administrador      -> control total, sin restricciones.
# 1002 Director            -> mismo nivel de acceso que 1001, EXCEPTO:
#                             no puede crear proyectos (solo elegir entre
#                             los que ya existen) y no puede eliminar
#                             usuarios con rol 1001.
# 1003 Jefe de Departamento -> puede descargar documentos, puede invitar
#                             (gestionar accesos) y subir fotos, pero NO
#                             puede subir guiones ni crear escenas o
#                             personajes.
# 1004 Onset                -> puede ver todo, subir fotografías y
#                             comentar en escenas. Sin permisos de
#                             administración.
# 1005 Usuario               -> solo lectura (visualizador).
#
# NOTA: "download_files", "upload_scripts", "create_scenes",
# "create_characters", "upload_photos" y "comment_scenes" todavía no
# tienen endpoints en este backend (guiones/escenas/personajes/fotos/
# comentarios no están implementados). Quedan listos en la matriz para
# que, cuando se creen esas rutas, solo haga falta agregar
# Depends(require_permission("<permiso>")) — sin tener que rediseñar
# el esquema de permisos.
#
# Desglose de producción (módulo "breakdown"), dos niveles:
#
# "manage_general_breakdown" -> crear/editar/eliminar el desglose
# GENERAL (categoría + item + cantidad por escena). Solo Administrador
# y Director, porque son quienes cargan/aprueban el desglose completo.
#
# "view_department_breakdown" -> ver la segmentación ESPECIFICA que
# hace cada área (ej. de "95 gente de mercado", cuántas mujeres,
# hombres, niños). Ojo: Administrador y Director NO tienen este
# permiso a propósito — ese nivel es exclusivo del equipo del
# departamento dueño del item (Jefe + Onset + Usuario de esa misma
# área). El filtro por id_departamento se hace además en el
# controller, este permiso solo controla el rol.
#
# "edit_department_breakdown" -> crear/editar/eliminar esa
# segmentación específica. Solo el Jefe de Departamento (1003); Onset
# y Usuario del mismo departamento pueden verla pero no modificarla.
#
# Papelera de reciclaje de fotos (2026-09-23, a pedido explícito):
# "delete_photos" ahora es un soft-delete (mueve la foto a la
# papelera, ver fotos_continuidad.eliminada), no un borrado real.
#
# "view_recycle_bin" -> ver la pantalla de Papelera de Reciclaje.
# Jefe de Departamento, Director y Administrador (este último de
# SOLO LECTURA: ve la papelera pero no tiene botones de acción, ver
# "manage_recycle_bin").
#
# "manage_recycle_bin" -> restaurar una foto o eliminarla
# DEFINITIVAMENTE desde la papelera. Exclusivo de Jefe de
# Departamento y Director — ni Onset ni Administrador pueden.
#
# Notificaciones (2026-09-27, a pedido explícito):
# "publish_notifications" -> publicar una notificación al equipo
# (general o específica de uno o más departamentos). Exclusivo de
# Jefe de Departamento y Director; el Administrador NO publica.
ROLE_PERMISSIONS = {
    ADMINISTRADOR: {
        "full_management": True,     # CRUD total de usuarios, clientes y roles
        "create_project": True,
        "manage_projects": True,     # editar / eliminar proyectos
        "invite_users": True,
        "delete_admin_users": True,  # puede eliminar usuarios con id_rol 1001
        "manage_team_status": True,  # suspender/reactivar (todo el proyecto)
        "download_files": True,
        "upload_scripts": True,
        "create_scenes": True,
        "create_characters": True,
        "upload_photos": True,
        "delete_photos": False,      # el Admin puede VER fotos pero no eliminarlas
        "comment_scenes": True,
        "read_only": False,
        "manage_general_breakdown": True,
        "view_department_breakdown": False,
        "edit_department_breakdown": False,
        "view_recycle_bin": True,    # solo lectura, ver "manage_recycle_bin"
        "manage_recycle_bin": False,
        "publish_notifications": False,
    },
    DIRECTOR: {
        "full_management": True,
        "create_project": False,
        "manage_projects": True,
        "invite_users": True,
        "delete_admin_users": False,
        "manage_team_status": True,  # suspender/reactivar (todo el proyecto)
        "download_files": True,
        "upload_scripts": True,
        "create_scenes": True,
        "create_characters": True,
        "upload_photos": True,
        "delete_photos": True,
        "comment_scenes": True,
        "read_only": False,
        "manage_general_breakdown": True,
        "view_department_breakdown": False,
        "edit_department_breakdown": False,
        "view_recycle_bin": True,
        "manage_recycle_bin": True,
        "publish_notifications": True,
    },
    JEFE_DEPARTAMENTO: {
        "full_management": False,
        "create_project": False,
        "manage_projects": False,
        "invite_users": True,
        "delete_admin_users": False,
        "manage_team_status": True,  # suspender/reactivar, SOLO su propio departamento (ver set_user_estado)
        "download_files": True,
        "upload_scripts": False,
        "create_scenes": False,
        "create_characters": False,
        "upload_photos": True,
        "delete_photos": True,
        "comment_scenes": False,
        "read_only": False,
        "manage_general_breakdown": False,
        "view_department_breakdown": True,
        "edit_department_breakdown": True,
        "view_recycle_bin": True,
        "manage_recycle_bin": True,
        "publish_notifications": True,
    },
    ONSET: {
        "full_management": False,
        "create_project": False,
        "manage_projects": False,
        "invite_users": False,
        "delete_admin_users": False,
        "manage_team_status": False,
        "download_files": False,
        "upload_scripts": False,
        "create_scenes": False,
        "create_characters": False,
        "upload_photos": True,
        "delete_photos": True,   # Onset puede mover fotos a la papelera (antes no podía eliminar)
        "comment_scenes": True,
        "read_only": False,
        "manage_general_breakdown": False,
        "view_department_breakdown": True,
        "edit_department_breakdown": False,
        "view_recycle_bin": False,   # no ve la pantalla de Papelera
        "manage_recycle_bin": False,
        "publish_notifications": False,
    },
    USUARIO: {
        "full_management": False,
        "create_project": False,
        "manage_projects": False,
        "invite_users": False,
        "delete_admin_users": False,
        "manage_team_status": False,
        "download_files": False,
        "upload_scripts": False,
        "create_scenes": False,
        "create_characters": False,
        "upload_photos": False,
        "delete_photos": False,
        "comment_scenes": False,
        "read_only": True,
        "manage_general_breakdown": False,
        "view_department_breakdown": True,
        "edit_department_breakdown": False,
        "view_recycle_bin": False,
        "manage_recycle_bin": False,
        "publish_notifications": False,
    },
}


# ==========================================
# HELPER
# ==========================================
def has_permission(id_rol: int, permission: str) -> bool:
    role = ROLE_PERMISSIONS.get(id_rol)

    if not role:
        return False

    return role.get(permission, False)
