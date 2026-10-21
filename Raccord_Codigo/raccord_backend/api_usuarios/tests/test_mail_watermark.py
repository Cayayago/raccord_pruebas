"""Sanitización de correos (anti-XSS / inyección de cabeceras) y marca de agua."""
import io
from datetime import datetime

import pytest
from pypdf import PdfReader
from reportlab.pdfgen import canvas

from app.utils import mail, watermark


# ------------------------------------------------ mail._safe
@pytest.mark.parametrize(
    "entrada, esperado",
    [
        (None, ""),
        ("hola", "hola"),
        (5, "5"),
        ("<script>alert(1)</script>", "&lt;script&gt;alert(1)&lt;/script&gt;"),
        ('a "b" & c', "a &quot;b&quot; &amp; c"),
        ("linea1\r\nBcc: x@evil.com", "linea1  Bcc: x@evil.com"),  # sin saltos: no hay inyección de cabeceras
    ],
)
def test_safe_escapa_html_y_aplasta_saltos(entrada, esperado):
    assert mail._safe(entrada) == esperado


@pytest.mark.parametrize(
    "entrada, esperado",
    [
        (None, ""),
        ("a\nb", "a<br>b"),
        ("a\r\nb", "a<br>b"),
        ("<b>x</b>\nfin", "&lt;b&gt;x&lt;/b&gt;<br>fin"),
    ],
)
def test_safe_multiline_conserva_saltos_pero_escapa(entrada, esperado):
    assert mail._safe_multiline(entrada) == esperado


# ------------------------------------------------ marca de agua
def _pdf(paginas: int) -> bytes:
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(300, 400))
    for i in range(paginas):
        c.drawString(20, 380, f"Pagina {i + 1}")
        c.showPage()
    c.save()
    return buf.getvalue()


@pytest.fixture()
def fecha_fija(monkeypatch):
    class _Dt:
        @staticmethod
        def now():
            return datetime(2026, 10, 20, 9, 5)

    monkeypatch.setattr(watermark, "datetime", _Dt)


def test_marca_de_agua_conserva_el_numero_de_paginas(fecha_fija):
    salida = watermark.add_watermark(_pdf(3), "ana@x.com")
    assert len(PdfReader(io.BytesIO(salida)).pages) == 3


def test_marca_de_agua_incluye_correo_y_fecha_en_cada_pagina(fecha_fija):
    salida = watermark.add_watermark(_pdf(2), "ana@x.com")
    for pagina in PdfReader(io.BytesIO(salida)).pages:
        texto = pagina.extract_text()
        assert "ana@x.com" in texto
        assert "2026-10-20 09:05" in texto


def test_marca_de_agua_no_borra_el_contenido_original(fecha_fija):
    salida = watermark.add_watermark(_pdf(1), "ana@x.com")
    assert "Pagina 1" in PdfReader(io.BytesIO(salida)).pages[0].extract_text()


def test_overlay_se_ajusta_al_tamano_de_la_pagina():
    overlay = watermark._build_overlay(200, 100, "x")
    caja = PdfReader(io.BytesIO(overlay)).pages[0].mediabox
    assert (float(caja.width), float(caja.height)) == (200.0, 100.0)
