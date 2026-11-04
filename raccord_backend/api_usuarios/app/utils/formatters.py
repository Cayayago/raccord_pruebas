# ==========================================
# FORMATEAR TEXTO (Primera letra mayúscula)
# ==========================================
def format_text(text):
    if text and isinstance(text, str):
        return text.strip().title()
    return text
