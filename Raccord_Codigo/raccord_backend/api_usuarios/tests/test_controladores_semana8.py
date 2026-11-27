"""Semana 8 (cobertura backend ≥ 80 %) — clientes, roles, Crew List y desgloses.

Se escogieron por lo que protegen, no por el número:
- clientes: una empresa solo ve la suya y no puede haber dos con el mismo correo;
- roles: el nombre del rol es único; un PATCH solo toca lo que se envía;
- Crew List: la persona se amarra a un proyecto y NO cambia de proyecto después;
- desgloses: un desglose con escenas asociadas no se puede borrar (la FK es CASCADE
  y se llevaría las escenas).
Sin BD: FakeSession (ignora los filtros; los casos donde el filtro importa están en
tests/integracion).
"""
from datetime import time

from app.controllers import breakdown_sheet_controller as hojas
from app.controllers import client_controller as clientes
from app.controllers import crew_member_controller as equipo
from app.controllers import role_controller as roles
from app.models.breakdown_model import DesgloseItem
from app.models.breakdown_sheet_model import BreakdownSheet
from app.models.client_model import Client
from app.models.crew_member_model import CrewMember
from app.models.department_model import Department
from app.models.role_model import Role
from app.models.scene_model import Scene
from app.schemas.breakdown_sheet_schema import BreakdownSheetSchema, BreakdownSheetUpdateSchema
from app.schemas.client_schema import ClientSchema, ClientUpdateSchema
from app.schemas.crew_member_schema import CrewMemberSchema, CrewMemberUpdateSchema
from app.schemas.role_schema import RoleSchema, RoleUpdateSchema
from tests.fakes import FakeSession, Obj


# ==========================================================
# CLIENTES (empresas)
# ==========================================================
def _cliente(**attrs):
    base = dict(
        id_cliente="c1", document="NIT", razon_social="Productora Uno", representante_legal="Ana Ruiz",
        email="uno@productora.com", address="Calle 1", telephone="123", number_cellphone="300", id_document="900123",
    )
    base.update(attrs)
    return Obj(**base)


def _esquema_cliente(**cambios):
    datos = dict(
        document="NIT", razon_social="Productora Uno", representante_legal="Ana Ruiz",
        email="uno@productora.com", id_document="900123",
    )
    datos.update(cambios)
    return ClientSchema(**datos)


def test_listar_clientes_devuelve_los_datos_de_la_empresa():
    db = FakeSession({Client: [_cliente()]})

    resp = clientes.get_clients("c1", db)

    assert resp["success"] is True
    assert resp["data"][0]["razon_social"] == "Productora Uno"
    assert resp["data"][0]["id_document"] == "900123"


def test_listar_clientes_sin_empresa_devuelve_lista_vacia():
    resp = clientes.get_clients("c1", FakeSession({Client: []}))

    assert resp["success"] is True and resp["data"] == []


def test_get_cliente_encontrado_y_no_encontrado():
    assert clientes.get_client("c1", FakeSession({Client: _cliente()}))["data"]["email"] == "uno@productora.com"

    faltante = clientes.get_client("zz", FakeSession({Client: None}))
    assert faltante["success"] is False and faltante["message"] == "Cliente no encontrado"


def test_crear_cliente_con_correo_repetido_se_rechaza_y_no_inserta():
    db = FakeSession({Client: _cliente()})  # ya existe un cliente con ese correo

    resp = clientes.create_client(_esquema_cliente(), db)

    assert resp["success"] is False and resp["error"] == "DUPLICATE_EMAIL"
    assert db.added == [] and db.commits == 0


def test_crear_cliente_nuevo_lo_guarda_con_sus_datos():
    db = FakeSession({Client: None})

    resp = clientes.create_client(_esquema_cliente(email="nuevo@productora.com"), db)

    assert resp["success"] is True and db.commits == 1
    assert db.added[0].email == "nuevo@productora.com"
    assert resp["data"]["email"] == "nuevo@productora.com"


def test_actualizar_cliente_completo_reemplaza_todos_los_campos():
    cliente = _cliente()
    db = FakeSession({Client: cliente})

    clientes.update_client_full("c1", _esquema_cliente(razon_social="Otra SAS", address="Calle 9"), db)

    assert cliente.razon_social == "Otra SAS" and cliente.address == "Calle 9"
    assert db.commits == 1


def test_actualizar_cliente_completo_inexistente():
    db = FakeSession({Client: None})

    resp = clientes.update_client_full("zz", _esquema_cliente(), db)

    assert resp["success"] is False and db.commits == 0


def test_patch_cliente_solo_cambia_lo_que_se_envia():
    cliente = _cliente()
    db = FakeSession({Client: cliente})

    clientes.update_client("c1", ClientUpdateSchema(telephone="999"), db)

    assert cliente.telephone == "999"
    assert cliente.razon_social == "Productora Uno"  # lo no enviado se conserva
    assert db.commits == 1


def test_patch_cliente_inexistente():
    resp = clientes.update_client("zz", ClientUpdateSchema(telephone="1"), FakeSession({Client: None}))

    assert resp["success"] is False and resp["message"] == "Cliente no encontrado"


def test_eliminar_cliente_existente_y_no_existente():
    cliente = _cliente()
    db = FakeSession({Client: cliente})

    assert clientes.delete_client("c1", db)["success"] is True
    assert db.deleted == [cliente] and db.commits == 1

    vacio = FakeSession({Client: None})
    assert clientes.delete_client("zz", vacio)["success"] is False
    assert vacio.deleted == []


# ==========================================================
# ROLES
# ==========================================================
def _rol(**attrs):
    base = dict(id_rol=1002, nombre="Director", nivel_jerarquia="alto", descripcion="Dirige", activo=True)
    base.update(attrs)
    return Obj(**base)


def test_listar_roles():
    db = FakeSession({Role: [_rol(), _rol(id_rol=1005, nombre="Usuario", activo=False)]})

    resp = roles.get_roles(db)

    assert [r["nombre"] for r in resp["data"]] == ["Director", "Usuario"]
    assert resp["data"][1]["activo"] is False


def test_get_rol_encontrado_y_no_encontrado():
    assert roles.get_role(1002, FakeSession({Role: _rol()}))["data"]["nivel_jerarquia"] == "alto"
    assert roles.get_role(9, FakeSession({Role: None}))["message"] == "Rol no encontrado"


def test_crear_rol_con_nombre_repetido_se_rechaza():
    db = FakeSession({Role: _rol()})

    resp = roles.create_role(RoleSchema(nombre="Director", nivel_jerarquia="alto"), db)

    assert resp["success"] is False and resp["error"] == "DUPLICATE_ROLE"
    assert db.added == []


def test_crear_rol_nuevo_queda_activo_por_defecto():
    db = FakeSession({Role: None})

    resp = roles.create_role(RoleSchema(nombre="Extra", nivel_jerarquia="bajo"), db)

    assert resp["success"] is True and db.commits == 1
    assert db.added[0].activo is True


def test_actualizar_rol_completo_y_patch_parcial():
    rol = _rol()
    db = FakeSession({Role: rol})

    roles.update_role_full(1002, RoleSchema(nombre="Director General", nivel_jerarquia="alto", activo=False), db)
    assert (rol.nombre, rol.activo) == ("Director General", False)

    roles.update_role(1002, RoleUpdateSchema(descripcion="Nueva"), db)
    assert rol.descripcion == "Nueva"
    assert rol.nombre == "Director General"  # el PATCH no pisa lo que no se envía


def test_actualizar_o_borrar_rol_inexistente():
    db = FakeSession({Role: None})

    assert roles.update_role_full(9, RoleSchema(nombre="x", nivel_jerarquia="y"), db)["success"] is False
    assert roles.update_role(9, RoleUpdateSchema(nombre="x"), db)["success"] is False
    assert roles.delete_role(9, db)["success"] is False
    assert db.commits == 0 and db.deleted == []


def test_eliminar_rol_existente():
    rol = _rol()
    db = FakeSession({Role: rol})

    assert roles.delete_role(1002, db)["success"] is True
    assert db.deleted == [rol]


# ==========================================================
# CREW LIST (personal del proyecto)
# ==========================================================
def _persona(**attrs):
    base = dict(
        id_crew="p1", nombre="Luis", cargo="Gaffer", id_departamento="d1", celular="300",
        correo="luis@x.com", notas=None, id_project="proy-1",
    )
    base.update(attrs)
    return Obj(**base)


def _depto(**attrs):
    base = dict(id_departamento="d1", nombre="Luces")
    base.update(attrs)
    return Obj(**base)


def test_listar_equipo_incluye_el_nombre_del_departamento():
    db = FakeSession({CrewMember: [(_persona(), _depto()), (_persona(id_crew="p2", id_departamento=None), None)]})

    resp = equipo.get_crew_members("proy-1", db)

    assert resp["data"][0]["departamento_nombre"] == "Luces"
    # Una persona sin departamento sigue apareciendo (LEFT JOIN), con el nombre vacío.
    assert resp["data"][1]["departamento_nombre"] is None


def test_get_persona_encontrada_y_no_encontrada():
    ok = equipo.get_crew_member("p1", FakeSession({CrewMember: (_persona(), _depto())}))
    assert ok["data"]["cargo"] == "Gaffer" and ok["data"]["departamento_nombre"] == "Luces"

    assert equipo.get_crew_member("zz", FakeSession({CrewMember: None}))["message"] == "Persona no encontrada"


def test_crear_persona_con_departamento_devuelve_su_nombre():
    db = FakeSession({Department: _depto()})
    datos = CrewMemberSchema(nombre="Luis", cargo="Gaffer", id_departamento="d1", id_project="proy-1")

    resp = equipo.create_crew_member(datos, db)

    assert db.commits == 1 and db.added[0].id_project == "proy-1"
    assert resp["data"]["departamento_nombre"] == "Luces"


def test_crear_persona_sin_departamento_no_consulta_departamentos():
    db = FakeSession()  # si consultara Department, el doble devolvería None igual; se comprueba el resultado
    datos = CrewMemberSchema(nombre="Rosa", cargo="Runner", id_project="proy-1")

    resp = equipo.create_crew_member(datos, db)

    assert resp["success"] is True and resp["data"]["departamento_nombre"] is None


def test_actualizar_persona_completo_no_cambia_de_proyecto():
    persona = _persona()
    db = FakeSession({CrewMember: persona, Department: _depto(nombre="Arte", id_departamento="d2")})
    datos = CrewMemberSchema(nombre="Luis M.", cargo="Best boy", id_departamento="d2", id_project="OTRO-PROYECTO")

    resp = equipo.update_crew_member_full("p1", datos, db)

    assert (persona.nombre, persona.cargo, persona.id_departamento) == ("Luis M.", "Best boy", "d2")
    # Mover a alguien de proyecto por un PUT sería un hueco de seguridad: se ignora.
    assert persona.id_project == "proy-1"
    assert resp["data"]["departamento_nombre"] == "Arte"


def test_patch_persona_solo_cambia_lo_enviado():
    persona = _persona()
    db = FakeSession({CrewMember: persona, Department: _depto()})

    equipo.update_crew_member("p1", CrewMemberUpdateSchema(celular="311"), db)

    assert persona.celular == "311" and persona.nombre == "Luis"


def test_actualizar_o_borrar_persona_inexistente():
    db = FakeSession({CrewMember: None})
    datos = CrewMemberSchema(nombre="x", cargo="y", id_project="p")

    assert equipo.update_crew_member_full("zz", datos, db)["success"] is False
    assert equipo.update_crew_member("zz", CrewMemberUpdateSchema(nombre="x"), db)["success"] is False
    assert equipo.delete_crew_member("zz", db)["success"] is False
    assert db.commits == 0


def test_eliminar_persona_existente():
    persona = _persona()
    db = FakeSession({CrewMember: persona})

    assert equipo.delete_crew_member("p1", db)["success"] is True
    assert db.deleted == [persona]


# ==========================================================
# DESGLOSES (hojas de desglose)
# ==========================================================
def _hoja(**attrs):
    base = dict(
        id_desglose="desg1", version="v1", semana_grabacion=2, dia_rodaje=3, hora_inicio=time(7, 30),
        hora_fin=None, location="Estudio", requerimientos="Grúa", activo=True, id_project="proy-1",
    )
    base.update(attrs)
    return Obj(**base)


def _escena(**attrs):
    base = dict(
        id_escena="e1", numero_de_escena=1, encabezado="INT. CASA - DÍA", descripcion="x", modo_vista="int",
        momento_dia="dia", ciudad="Bogotá", pagina="1", dia_dramatico=1,
    )
    base.update(attrs)
    return Obj(**base)


def _item(**attrs):
    base = dict(id_desglose_item="i1", id_escena="e1", id_departamento="d1", categoria="Utilería", nombre_item="Taza", cantidad=2)
    base.update(attrs)
    return Obj(**base)


def test_listar_desgloses_serializa_las_horas_como_texto():
    resp = hojas.get_breakdown_sheets("proy-1", FakeSession({BreakdownSheet: [_hoja()]}))

    fila = resp["data"][0]
    assert fila["hora_inicio"] == "07:30:00"
    assert fila["hora_fin"] is None  # sin hora no se inventa un valor


def test_get_desglose_trae_sus_escenas_y_los_items_de_esas_escenas():
    db = FakeSession({BreakdownSheet: _hoja(), Scene: [_escena(), _escena(id_escena="e2")], DesgloseItem: [_item()]})

    resp = hojas.get_breakdown_sheet("desg1", db)

    assert [e["id_escena"] for e in resp["data"]["escenas"]] == ["e1", "e2"]
    assert resp["data"]["items_generales"][0]["nombre_item"] == "Taza"


def test_get_desglose_sin_escenas_no_busca_items():
    db = FakeSession({BreakdownSheet: _hoja(), Scene: [], DesgloseItem: [_item()]})

    resp = hojas.get_breakdown_sheet("desg1", db)

    # Aunque existan items sueltos, sin escenas asociadas no se devuelve ninguno.
    assert resp["data"]["escenas"] == [] and resp["data"]["items_generales"] == []


def test_get_desglose_inexistente():
    resp = hojas.get_breakdown_sheet("zz", FakeSession({BreakdownSheet: None}))

    assert resp["success"] is False and resp["message"] == "Desglose no encontrado"


def test_crear_desglose_queda_activo_si_no_se_indica():
    db = FakeSession()
    datos = BreakdownSheetSchema(version="v1", requerimientos="Grúa", activo=None, id_project="proy-1")

    resp = hojas.create_breakdown_sheet(datos, db)

    assert db.commits == 1 and db.added[0].activo is True
    assert resp["data"]["id_project"] == "proy-1"


def test_actualizar_desglose_completo_no_cambia_de_proyecto_y_respeta_inactivo():
    hoja = _hoja()
    db = FakeSession({BreakdownSheet: hoja})
    datos = BreakdownSheetSchema(version="v2", requerimientos="Nada", activo=False, id_project="OTRO")

    hojas.update_breakdown_sheet_full("desg1", datos, db)

    assert (hoja.version, hoja.activo) == ("v2", False)
    assert hoja.id_project == "proy-1"


def test_patch_desglose_solo_cambia_lo_enviado():
    hoja = _hoja()
    db = FakeSession({BreakdownSheet: hoja})

    hojas.update_breakdown_sheet("desg1", BreakdownSheetUpdateSchema(location="Locación B"), db)

    assert hoja.location == "Locación B" and hoja.version == "v1"


def test_actualizar_desglose_inexistente():
    db = FakeSession({BreakdownSheet: None})
    datos = BreakdownSheetSchema(version="v", requerimientos="r", id_project="p")

    assert hojas.update_breakdown_sheet_full("zz", datos, db)["success"] is False
    assert hojas.update_breakdown_sheet("zz", BreakdownSheetUpdateSchema(version="v"), db)["success"] is False


def test_no_se_borra_un_desglose_con_escenas_asociadas():
    db = FakeSession({BreakdownSheet: _hoja(), Scene: [_escena(), _escena(id_escena="e2")]})

    resp = hojas.delete_breakdown_sheet("desg1", db)

    assert resp["success"] is False and resp["error"] == "BREAKDOWN_SHEET_IN_USE"
    assert "2 escena(s)" in resp["message"]
    assert db.deleted == [] and db.commits == 0


def test_se_borra_un_desglose_sin_escenas_y_se_rechaza_uno_inexistente():
    hoja = _hoja()
    db = FakeSession({BreakdownSheet: hoja, Scene: []})

    assert hojas.delete_breakdown_sheet("desg1", db)["success"] is True
    assert db.deleted == [hoja]

    assert hojas.delete_breakdown_sheet("zz", FakeSession({BreakdownSheet: None}))["success"] is False
