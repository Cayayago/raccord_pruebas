"""Parser de guiones (app/utils/script_parser.py).

Las funciones puras se prueban con texto; `parse_script` con un PDF
generado en memoria con reportlab (sin archivos ni red).
"""
import io

import pytest
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from app.utils import script_parser as sp


# ------------------------------------------------ normalizadores
@pytest.mark.parametrize(
    "crudo, esperado",
    [
        ("INT", "int"), ("EXT.", "ext"), ("int.", "int"),
        ("INT/EXT", "int/ext"), ("EXT / INT", "ext/int"), ("INT./EXT.", "int/ext"),
        ("XXX", None),
    ],
)
def test_normalize_modo_vista(crudo, esperado):
    assert sp._normalize_modo_vista(crudo) == esperado


@pytest.mark.parametrize(
    "crudo, esperado",
    [
        ("DIA", "dia"), ("DÍA", "dia"), ("noche", "noche"), ("AMANECER", "amanecer"),
        ("ANOCHECER", "atardecer"), ("MADRUGADA", "noche"), ("TARDE", "dia"),
        ("DÍA/NOCHE", "dia/noche"),
        ("MAÑ ANA", "dia"),   # espacio espurio de pypdf tras la ñ
        ("SIEMPRE", None),
    ],
)
def test_normalize_momento_dia(crudo, esperado):
    assert sp._normalize_momento_dia(crudo) == esperado


def test_normalize_whitespace_colapsa_saltos_y_espacios():
    assert sp._normalize_whitespace("  a \n\t b   c ") == "a b c"


# ------------------------------------------------ nombres de personaje
@pytest.mark.parametrize(
    "nombre, esperado",
    [
        ("JULIÁN", "JULIÁN"),
        ("ANA MARÍA", "ANA MARÍA"),
        ("A B C", "A B C"),              # 3 palabras: límite válido
        ("A B C D", None),               # 4 palabras: límite inválido
        ("X", None),                     # menos de 2 caracteres
        ("FADE IN", None),               # lista de no-personajes
        ("V.O.", None),
        ("PENSAMIENTO PENSAMIENTO", None),  # palabra repetida
        ("  ELENA  ", "ELENA"),
    ],
)
def test_clean_character_name(nombre, esperado):
    assert sp._clean_character_name(nombre) == esperado


# ------------------------------------------------ detección de encabezados
def _encabezados(texto):
    return [m["encabezado"] for m in sp._find_scene_matches(texto)]


def test_detecta_slugline_estandar_con_numero_de_escena():
    texto = "ESC 4. EXT. CARRERA SÉPTIMA / CALLES DEL CENTRO - DÍA Julián camina."
    assert _encabezados(texto) == ["ESC 4. EXT. CARRERA SÉPTIMA / CALLES DEL CENTRO - DÍA"]


def test_detecta_slugline_sin_numero_y_sin_espacio_antes_del_guion():
    assert _encabezados("INT. BAÑO- NOCHE Ella entra.") == ["INT. BAÑO- NOCHE"]


def test_acepta_guion_largo_y_en_dash():
    assert len(_encabezados("EXT. LAGUNA – DÍA texto. INT. CASA — NOCHE otro texto.")) == 2


def test_palabras_que_contienen_ext_o_int_no_son_encabezado():
    # Regresión: "Extendida"/"Internacional" no deben iniciar una escena.
    assert _encabezados("Versión Extendida - DÍA e Internacional - NOCHE") == []


def test_detecta_formato_alterno_momento_antes_del_lugar():
    texto = "INT. NOCHE. CENTRO DE LA TIERRA1 1 Alguien baja."
    m = sp._find_scene_matches(texto)
    assert len(m) == 1
    assert m[0]["encabezado"] == "INT. NOCHE. CENTRO DE LA TIERRA"


def test_lugar_de_mas_de_100_caracteres_no_se_traga_el_texto():
    # Límite del tope de 100 caracteres: un "lugar" larguísimo no es slugline.
    texto = "INT. " + ("X" * 150) + " - DÍA"
    assert sp._find_scene_matches(texto) == []


# ------------------------------------------------ parse_script (PDF real en memoria)
def _pdf(paginas: list[list[str]]) -> bytes:
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    for lineas in paginas:
        y = 800
        for linea in lineas:
            c.drawString(50, y, linea)
            y -= 18
        c.showPage()
    c.save()
    return buf.getvalue()


GUION = [
    [
        "INT. REDACCION - DIA",
        "Julian entra con prisa.",
        "JULIAN Necesito el informe ya.",
        "ELENA Todavia no esta listo.",
    ],
    [
        "EXT. CALLE - NOCHE",
        "Llueve sin parar.",
        "JULIAN Esto no puede ser.",
        "ELENA Tranquilo, respira.",
        "FIGURANTE Disculpe, senor.",
    ],
]


def test_parse_script_cuenta_escenas_y_clasifica_cada_una():
    out = sp.parse_script(_pdf(GUION))
    assert [e["modo_vista"] for e in out["escenas"]] == ["int", "ext"]
    assert [e["momento_dia"] for e in out["escenas"]] == ["dia", "noche"]
    assert [e["numero_de_escena"] for e in out["escenas"]] == ["1", "2"]


def test_parse_script_reporta_la_pagina_de_cada_escena():
    out = sp.parse_script(_pdf(GUION))
    assert [e["pagina"] for e in out["escenas"]] == [1, 2]


def test_parse_script_solo_acepta_personajes_con_2_o_mas_intervenciones():
    # JULIAN y ELENA hablan 2 veces; FIGURANTE una sola: se descarta.
    out = sp.parse_script(_pdf(GUION))
    assert "JULIAN" in out["personajes_detectados"]
    assert "ELENA" in out["personajes_detectados"]
    assert "FIGURANTE" not in out["personajes_detectados"]


def test_parse_script_asigna_personajes_a_su_escena():
    out = sp.parse_script(_pdf(GUION))
    assert set(out["escenas"][0]["personajes_detectados"]) == {"JULIAN", "ELENA"}


def test_parse_script_sin_encabezados_devuelve_listas_vacias():
    out = sp.parse_script(_pdf([["Texto suelto sin formato de guion."]]))
    assert out == {"escenas": [], "personajes_detectados": []}
