"""Reglas de validación de entrada (Pydantic) — contratos de la API.

Cada test comprueba una regla real: límites de contraseña, catálogos
cerrados (Literal), correos, campos trampa, etc. No hay BD ni red.
"""
from datetime import date

import pytest
from pydantic import ValidationError

from app.schemas.contact_schema import ContactSchema
from app.schemas.login_schema import LoginSchema, TwoFactorSendSchema, TwoFactorVerifySchema
from app.schemas.module_access_schema import ModuleAccessSetSchema
from app.schemas.password_schema import RecoverSchema, ResetPasswordSchema
from app.schemas.project_schema import ProjectCreateSchema, ProjectSchema, ProjectUpdateSchema
from app.schemas.register_schema import InviteItemSchema, RegisterSchema
from app.schemas.scene_schema import SceneSchema, SceneUpdateSchema
from app.schemas.script_schema import ScriptSchema, ScriptUpdateSchema, SegmentarScriptSchema
from app.schemas.user_schema import (
    ChangePasswordSchema,
    UserProfileUpdateSchema,
    UserProjectSchema,
    UserSchema,
    UserUpdateSchema,
)


def _registro(**cambios):
    base = dict(
        razon_social="Producciones SAS", representante_legal="Ana", email_empresa="e@x.com",
        document="900123", id_document="NIT", nombre="Ana", apellido="Ruiz",
        mail="ana@x.com", msisdn="3001234567", contrasena="12345678",
    )
    base.update(cambios)
    return RegisterSchema(**base)


# ------------------------------------------------ contraseña: 8..72 caracteres
@pytest.mark.parametrize("largo", [8, 9, 71, 72])
def test_contrasena_dentro_del_rango_es_valida(largo):
    assert _registro(contrasena="a" * largo).contrasena == "a" * largo


@pytest.mark.parametrize("largo", [0, 1, 7, 73, 100])
def test_contrasena_fuera_del_rango_es_rechazada(largo):
    with pytest.raises(ValidationError):
        _registro(contrasena="a" * largo)


def test_cambio_y_reseteo_de_contrasena_usan_el_mismo_rango():
    ChangePasswordSchema(contrasena_actual="x", nueva_contrasena="a" * 8)
    with pytest.raises(ValidationError):
        ChangePasswordSchema(contrasena_actual="x", nueva_contrasena="a" * 7)
    with pytest.raises(ValidationError):
        ResetPasswordSchema(mail="a@x.com", codigo="1", nueva_contrasena="a" * 73)


def test_actualizar_usuario_valida_contrasena_solo_si_viene():
    assert UserUpdateSchema().contrasena is None
    with pytest.raises(ValidationError):
        UserUpdateSchema(contrasena="corta")


# ------------------------------------------------ correos
@pytest.mark.parametrize("mail", ["sin-arroba", "a@", "@x.com", "a b@x.com", ""])
def test_correo_invalido_es_rechazado_en_login(mail):
    with pytest.raises(ValidationError):
        LoginSchema(mail=mail, contrasena="x")


def test_correo_valido_en_login_y_2fa():
    assert LoginSchema(mail="a@x.com", contrasena="x").mail == "a@x.com"
    TwoFactorSendSchema(mail="a@x.com", device_id="d", contrasena="x")
    TwoFactorVerifySchema(mail="a@x.com", codigo="123456", device_id="d", contrasena="x")


def test_recuperar_contrasena_exige_correo_valido():
    with pytest.raises(ValidationError):
        RecoverSchema(mail="no-es-correo")


def test_invitado_exige_rol_numerico():
    InviteItemSchema(nombre_completo="A B", mail="a@x.com", id_departamento="area01", id_rol=1004)
    with pytest.raises(ValidationError):
        InviteItemSchema(nombre_completo="A B", mail="a@x.com", id_departamento="area01", id_rol="jefe")


# ------------------------------------------------ formulario de contacto (público)
def _contacto(**cambios):
    base = dict(nombre="Ana", email="a@x.com", mensaje="Hola")
    base.update(cambios)
    return ContactSchema(**base)


def test_contacto_aplica_valores_por_defecto():
    c = _contacto()
    assert c.tipo == "demo" and c.honeypot == "" and c.celular == ""


@pytest.mark.parametrize("campo, valor", [("nombre", ""), ("mensaje", ""), ("nombre", "x" * 121), ("mensaje", "x" * 3001)])
def test_contacto_rechaza_vacios_y_excesos(campo, valor):
    with pytest.raises(ValidationError):
        _contacto(**{campo: valor})


@pytest.mark.parametrize("campo, largo", [("nombre", 120), ("mensaje", 3000), ("celular", 30), ("honeypot", 200)])
def test_contacto_acepta_el_largo_maximo_exacto(campo, largo):
    assert len(getattr(_contacto(**{campo: "x" * largo}), campo)) == largo


def test_contacto_rechaza_honeypot_gigante():
    with pytest.raises(ValidationError):
        _contacto(honeypot="x" * 201)


# ------------------------------------------------ catálogos cerrados (Literal)
@pytest.mark.parametrize("estado", ["preliminar", "en_rodaje", "suspendido", "finalizado"])
def test_estados_de_proyecto_validos(estado):
    assert ProjectUpdateSchema(estado=estado).estado == estado


@pytest.mark.parametrize("estado", ["Preliminar", "activo", "", "cancelado"])
def test_estado_de_proyecto_fuera_del_catalogo(estado):
    with pytest.raises(ValidationError):
        ProjectUpdateSchema(estado=estado)


@pytest.mark.parametrize("causal", ["temporal", "indefinido", "incumplimiento"])
def test_causales_de_suspension_validas(causal):
    assert ProjectUpdateSchema(causal_suspension=causal).causal_suspension == causal


def test_causal_de_suspension_invalida():
    with pytest.raises(ValidationError):
        ProjectUpdateSchema(causal_suspension="vacaciones")


def test_crear_proyecto_exige_nombre_formato_genero_cliente_y_usuario():
    ok = dict(project_name="P", formato_de_produccion="Serie", genero="Drama", id_client="c", id_user="u")
    ProjectCreateSchema(**ok)
    for faltante in ok:
        incompleto = {k: v for k, v in ok.items() if k != faltante}
        with pytest.raises(ValidationError):
            ProjectCreateSchema(**incompleto)
    ProjectSchema(project_name="P", formato_de_produccion="Serie", genero="Drama", id_client="c")


@pytest.mark.parametrize("modo", ["int", "ext", "int/ext", "ext/int"])
def test_modos_de_vista_validos(modo):
    assert SceneSchema(numero_de_escena="1", encabezado="E", modo_vista=modo).modo_vista == modo


@pytest.mark.parametrize("modo", ["INT", "interior", "ext/ext", ""])
def test_modo_de_vista_invalido(modo):
    with pytest.raises(ValidationError):
        SceneSchema(numero_de_escena="1", encabezado="E", modo_vista=modo)


@pytest.mark.parametrize("momento", ["dia", "noche", "amanecer", "atardecer", "anochecer"])
def test_momentos_del_dia_validos(momento):
    assert SceneUpdateSchema(momento_dia=momento).momento_dia == momento


def test_momento_del_dia_combinado_no_se_acepta():
    with pytest.raises(ValidationError):
        SceneUpdateSchema(momento_dia="dia/noche")


def test_estado_de_escena_por_defecto_es_pendiente():
    assert SceneSchema(numero_de_escena="1", encabezado="E").estado == "Pendiente"


@pytest.mark.parametrize("estado", ["Pendiente", "En proceso", "Finalizada", "Eliminada"])
def test_estados_de_escena_validos(estado):
    assert SceneUpdateSchema(estado=estado).estado == estado


def test_estado_de_escena_distingue_mayusculas():
    with pytest.raises(ValidationError):
        SceneUpdateSchema(estado="pendiente")


def test_escena_exige_numero_y_encabezado():
    with pytest.raises(ValidationError):
        SceneSchema(numero_de_escena="1")
    with pytest.raises(ValidationError):
        SceneSchema(encabezado="E")


def test_pagina_de_escena_debe_ser_entero():
    with pytest.raises(ValidationError):
        SceneSchema(numero_de_escena="1", encabezado="E", pagina="abc")


@pytest.mark.parametrize("estado", ["Borrador", "Revisión", "Aprobado", "En Rodaje", "Archivado"])
def test_estados_de_guion_validos(estado):
    s = ScriptSchema(numero_de_version="1", fecha_de_emision=date(2026, 1, 1), estado=estado, nombre="G")
    assert s.estado == estado and s.archivo == ""


def test_estado_de_guion_invalido():
    with pytest.raises(ValidationError):
        ScriptUpdateSchema(estado="Publicado")


def test_segmentar_por_defecto_solo_previsualiza():
    assert SegmentarScriptSchema().confirmar is False


# ------------------------------------------------ niveles de acceso por módulo
@pytest.mark.parametrize("nivel", ["sin_acceso", "ver", "comentar", "editar", "administrar"])
def test_nivel_de_acceso_valido(nivel):
    assert ModuleAccessSetSchema(nivel=nivel).nivel == nivel


def test_nivel_de_acceso_invalido_lista_las_opciones():
    with pytest.raises(ValidationError) as e:
        ModuleAccessSetSchema(nivel="dios")
    assert "sin_acceso" in str(e.value)


# ------------------------------------------------ perfil y usuario
def test_perfil_no_acepta_cambiar_rol_ni_correo_ni_estado():
    # Los campos sensibles no existen en el schema: se ignoran, no se asignan.
    p = UserProfileUpdateSchema(nombre="Ana", id_rol=1001, mail="x@x.com", estado="activo")
    assert not hasattr(p, "id_rol") and not hasattr(p, "mail") and not hasattr(p, "estado")


def test_vinculo_usuario_proyecto_por_defecto_es_rol_usuario():
    assert UserProjectSchema(id_user="u", id_project="p").id_rol == 1005


def test_usuario_completo_exige_todos_los_campos():
    with pytest.raises(ValidationError):
        UserSchema(nombre="Ana")
