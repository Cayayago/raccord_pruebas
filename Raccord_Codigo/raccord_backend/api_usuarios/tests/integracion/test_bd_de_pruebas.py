"""Semana 6 — la BD de pruebas es la que describe producción.

Estos tests no prueban una función del proyecto: comprueban que el entorno de
integración es confiable antes de apoyarse en él. La conexión llega por
DATABASE_URL (ver conftest.py); sin esa variable se saltan.
"""
from sqlalchemy import text


def test_roles_de_sistema_existen_con_los_ids_que_espera_el_codigo(db_session):
    # permissions.py tiene fijos los ids 1001-1005: si las migraciones no los
    # dejaron en la BD, ningún endpoint con permisos funcionaría.
    ids = [fila[0] for fila in db_session.execute(text("select id_rol from roles order by id_rol"))]

    assert ids == [1001, 1002, 1003, 1004, 1005]


def test_la_bd_de_pruebas_empieza_sin_usuarios(db_session):
    # Si este test falla, algún test dejó datos: la limpieza es el rollback
    # del fixture db_session y ninguno debe hacer commit real.
    assert db_session.execute(text("select count(*) from users")).scalar() == 0


def test_un_insert_hecho_en_un_test_no_sobrevive_al_siguiente(db_session):
    # Prepara sus propios datos y los confirma con commit(), como hace el
    # código de la app. El fixture lo convierte en un savepoint, así que el
    # rollback final lo deshace igual (lo verifica el test anterior al correr
    # la suite dos veces seguidas).
    db_session.execute(text("insert into departamentos (nombre, ubicacion) values ('Dep prueba', 'Set')"))
    db_session.commit()

    cuenta = db_session.execute(text("select count(*) from departamentos where nombre = 'Dep prueba'")).scalar()
    assert cuenta == 1
