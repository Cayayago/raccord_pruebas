"""
Utilidad para superponer una marca de agua diagonal y repetida
("tiled") sobre cada pagina de un PDF, con el correo de quien lo
descarga y la fecha/hora de la descarga, para trazabilidad.
"""

import io
from datetime import datetime

from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.colors import Color


def _build_overlay(width: float, height: float, text: str) -> bytes:
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=(width, height))

    c.saveState()
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(Color(0.5, 0.5, 0.5, alpha=0.25))

    step_x = 220
    step_y = 130

    y = 0
    while y < height + step_y:
        x = -100
        while x < width + step_x:
            c.saveState()
            c.translate(x, y)
            c.rotate(45)
            c.drawString(0, 0, text)
            c.restoreState()
            x += step_x
        y += step_y

    c.restoreState()
    c.save()
    buffer.seek(0)
    return buffer.read()


def add_watermark(pdf_bytes: bytes, mail: str) -> bytes:
    fecha = datetime.now().strftime("%Y-%m-%d %H:%M")
    texto = f"{mail} - {fecha}"

    reader = PdfReader(io.BytesIO(pdf_bytes))
    writer = PdfWriter()

    for page in reader.pages:
        width = float(page.mediabox.width)
        height = float(page.mediabox.height)

        overlay_bytes = _build_overlay(width, height, texto)
        overlay_reader = PdfReader(io.BytesIO(overlay_bytes))
        overlay_page = overlay_reader.pages[0]

        page.merge_page(overlay_page)
        writer.add_page(page)

    output = io.BytesIO()
    writer.write(output)
    output.seek(0)
    return output.read()
