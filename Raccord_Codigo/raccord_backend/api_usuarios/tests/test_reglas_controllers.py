"""Reglas de negocio puras que viven dentro de controllers.

Solo se importan las funciones sin I/O; ninguna toca BD ni MinIO.
"""
import pytest

from app.controllers.gallery_photo_controller import MAX_FILE_SIZE_BYTES, _like_escape
from app.controllers.project_controller import _normalizar_estado


# ------------------------------------------------ suspensión de proyectos
def test_suspendido_con_causal_es_valido():
    assert _normalizar_estado("suspendido", "temporal") == ("suspendido", "temporal", None)


@pytest.mark.parametrize("causal", [None, ""])
def test_suspendido_sin_causal_es_error(causal):
    estado, c, error = _normalizar_estado("suspendido", causal)
    assert estado is None and c is None
    assert "requiere una causal" in error


@pytest.mark.parametrize("estado", ["preliminar", "en_rodaje", "finalizado", None])
def test_causal_fuera_de_suspension_es_error(estado):
    resultado = _normalizar_estado(estado, "temporal")
    assert resultado[:2] == (None, None)
    assert "solo aplica" in resultado[2]


@pytest.mark.parametrize("estado", ["preliminar", "en_rodaje", "finalizado", None])
def test_estado_normal_sin_causal_es_valido(estado):
    assert _normalizar_estado(estado, None) == (estado, None, None)


# ------------------------------------------------ búsqueda de fotos
@pytest.mark.parametrize(
    "texto, esperado",
    [
        ("simple", "simple"),
        ("100%", "100\\%"),
        ("a_b", "a\\_b"),
        ("c:\\ruta", "c:\\\\ruta"),
        ("%_\\", "\\%\\_\\\\"),
        ("", ""),
    ],
)
def test_like_escape_neutraliza_comodines(texto, esperado):
    # Evita que un usuario use % o _ para forzar búsquedas amplias.
    assert _like_escape(texto) == esperado


def test_tope_de_tamano_de_foto_es_15_mb():
    assert MAX_FILE_SIZE_BYTES == 15 * 1024 * 1024
