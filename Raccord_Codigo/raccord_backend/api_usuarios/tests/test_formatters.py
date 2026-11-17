"""app/utils/formatters.py"""
import pytest

from app.utils.formatters import format_text


@pytest.mark.parametrize(
    "entrada, esperado",
    [
        ("  juan pérez ", "Juan Pérez"),
        ("MARÍA", "María"),
        ("ana", "Ana"),
        ("", ""),
        ("   ", ""),
    ],
)
def test_format_text_recorta_y_capitaliza(entrada, esperado):
    assert format_text(entrada) == esperado


@pytest.mark.parametrize("no_texto", [None, 5, ["a"]])
def test_format_text_devuelve_sin_cambios_lo_que_no_es_texto(no_texto):
    assert format_text(no_texto) == no_texto
