"""Reglas de negocio: matriz de permisos por rol (app/utils/permissions.py)."""
import pytest

from app.utils.permissions import (
    ADMINISTRADOR,
    DIRECTOR,
    JEFE_DEPARTAMENTO,
    ONSET,
    ROLE_PERMISSIONS,
    USUARIO,
    has_permission,
)


@pytest.mark.parametrize(
    "rol, permiso, esperado",
    [
        # Solo el Administrador crea proyectos (el Director elige entre existentes).
        (ADMINISTRADOR, "create_project", True),
        (DIRECTOR, "create_project", False),
        (JEFE_DEPARTAMENTO, "create_project", False),
        # Solo el Administrador puede eliminar usuarios administradores.
        (ADMINISTRADOR, "delete_admin_users", True),
        (DIRECTOR, "delete_admin_users", False),
        # Regla particular: el Admin ve fotos pero NO las elimina.
        (ADMINISTRADOR, "delete_photos", False),
        (DIRECTOR, "delete_photos", True),
        (ONSET, "delete_photos", True),
        # La papelera: Admin solo lee, Director y Jefe gestionan, Onset no entra.
        (ADMINISTRADOR, "view_recycle_bin", True),
        (ADMINISTRADOR, "manage_recycle_bin", False),
        (DIRECTOR, "manage_recycle_bin", True),
        (JEFE_DEPARTAMENTO, "manage_recycle_bin", True),
        (ONSET, "view_recycle_bin", False),
        # Notificaciones: publican Director y Jefe, no el Administrador.
        (DIRECTOR, "publish_notifications", True),
        (JEFE_DEPARTAMENTO, "publish_notifications", True),
        (ADMINISTRADOR, "publish_notifications", False),
        (ONSET, "publish_notifications", False),
        # Desglose por departamento: nivel exclusivo del equipo del área.
        (ADMINISTRADOR, "view_department_breakdown", False),
        (DIRECTOR, "view_department_breakdown", False),
        (JEFE_DEPARTAMENTO, "edit_department_breakdown", True),
        (ONSET, "edit_department_breakdown", False),
        (USUARIO, "view_department_breakdown", True),
        # Jefe de departamento: invita pero no sube guiones ni crea escenas.
        (JEFE_DEPARTAMENTO, "invite_users", True),
        (JEFE_DEPARTAMENTO, "upload_scripts", False),
        (JEFE_DEPARTAMENTO, "create_scenes", False),
        # Onset comenta escenas y sube fotos; Usuario es solo lectura.
        (ONSET, "comment_scenes", True),
        (ONSET, "upload_photos", True),
        (USUARIO, "upload_photos", False),
        (USUARIO, "read_only", True),
    ],
)
def test_has_permission_segun_matriz_de_roles(rol, permiso, esperado):
    # Arrange: rol y permiso parametrizados.
    # Act
    resultado = has_permission(rol, permiso)
    # Assert
    assert resultado is esperado


@pytest.mark.parametrize("rol_inexistente", [0, 1000, 1006, -1, None])
def test_has_permission_rol_desconocido_se_niega_siempre(rol_inexistente):
    # Valores límite alrededor del rango válido 1001..1005: denegar por defecto.
    assert has_permission(rol_inexistente, "full_management") is False


def test_has_permission_permiso_inexistente_se_niega():
    assert has_permission(ADMINISTRADOR, "permiso_que_no_existe") is False


def test_roles_validos_son_exactamente_los_cinco_acordados():
    assert sorted(ROLE_PERMISSIONS) == [1001, 1002, 1003, 1004, 1005]


def test_todos_los_roles_definen_el_mismo_conjunto_de_permisos():
    # Evita que se agregue un permiso a un rol y se olvide en los demás
    # (un permiso ausente se leería como False en silencio).
    conjuntos = {rol: set(p) for rol, p in ROLE_PERMISSIONS.items()}
    referencia = conjuntos[ADMINISTRADOR]
    for rol, permisos in conjuntos.items():
        assert permisos == referencia, f"El rol {rol} difiere en: {permisos ^ referencia}"


def test_solo_el_rol_usuario_es_de_solo_lectura():
    solo_lectura = [r for r, p in ROLE_PERMISSIONS.items() if p["read_only"]]
    assert solo_lectura == [USUARIO]
