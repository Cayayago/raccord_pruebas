"""
Parser heurístico de guiones (PDF -> escenas + personajes detectados).

Enfoque elegido A PROPÓSITO (decisión explícita del usuario, en vez de
mandar el guion a un modelo de IA): reglas de texto/expresiones
regulares sobre encabezados de escena ("sluglines") con el formato
estándar de guion. Es gratis y rápido, pero depende de que el PDF
tenga texto real (no escaneado) y de que el guion esté razonablemente
bien formateado — guiones con formato muy irregular pueden salir con
escenas mal separadas o personajes de menos. Documentado también en el
mensaje que ve el usuario en el frontend.

No usa ninguna librería de "parsing de guiones" porque no hay ninguna
bien mantenida en el ecosistema Python/pub — se arma a mano con
regex, que para sluglines es un patrón bastante estable y conocido.

DISEÑO IMPORTANTE (aprendido depurando un caso real): `pypdf.extract_text()`
NO reconstruye saltos de línea de forma confiable, y ese comportamiento
además CAMBIA entre versiones de pypdf — la misma librería puede
entregar "una palabra por línea" en una versión y "el encabezado pegado
al párrafo siguiente en una sola línea" en otra. Cualquier parser que
dependa de dónde pypdf decide cortar las líneas es frágil y se puede
romper con solo actualizar la librería.

Por eso este parser NO trabaja línea por línea: normaliza todo el
espacio en blanco (saltos de línea incluidos) a espacios simples,
reconstruyendo el texto de cada página como un párrafo continuo, y
busca los encabezados de escena y las intervenciones de personajes
directamente sobre ese texto continuo con `re.finditer` (sin anclar a
"^"/"$" de línea). Esto es indiferente a cómo la librería de turno
decida partir las líneas.
"""
import io
import re
from collections import OrderedDict

from pypdf import PdfReader

# ==========================================
# ENCABEZADO DE ESCENA ("slugline")
# ==========================================
# Cubre variantes reales vistas en guiones típicos:
#   "ESC 4. EXT. CARRERA SÉPTIMA / CALLES DEL CENTRO - DÍA"
#   "ESC 1. INT. REDACCIÓN EL ESPECTADOR - DÍA"
#   "INT. BAÑO- NOCHE"                (sin "ESC N.", sin espacio antes del "-")
#   "EXT./INT. AUTO - DÍA"
# Estructura: [ESC/ESCENA N.] (INT|EXT|INT/EXT|EXT/INT) LUGAR - MOMENTO
#
# El momento del día se matchea contra una lista cerrada de palabras
# conocidas (DIA, NOCHE, etc.) con límite de palabra ("\b"), en vez de
# depender de dónde termina la "línea" — así detecta el encabezado
# aunque venga pegado al texto de acción que le sigue en el mismo
# párrafo normalizado.
_MODO_VISTA_MAP = {
    "INT": "int",
    "EXT": "ext",
    "INT/EXT": "int/ext",
    "EXT/INT": "ext/int",
}

_MOMENTO_DIA_MAP = {
    "DIA": "dia",
    "DÍA": "dia",
    "NOCHE": "noche",
    "AMANECER": "amanecer",
    "ATARDECER": "atardecer",
    "ANOCHECER": "atardecer",
    "TARDE": "dia",
    "MAÑANA": "dia",
    "MEDIODIA": "dia",
    "MEDIODÍA": "dia",
    "MADRUGADA": "noche",
    "DIA/NOCHE": "dia/noche",
    "DÍA/NOCHE": "dia/noche",
    "AMANECER/DIA": "amanecer/dia",
    "AMANECER/DÍA": "amanecer/dia",
}

# Ordenadas de más larga a más corta para que "DIA/NOCHE" no se corte
# en "DIA" cuando ambas son candidatas (alternancia regex prueba en orden).
_MOMENTO_PALABRAS = sorted(_MOMENTO_DIA_MAP.keys(), key=len, reverse=True)

# BUG REAL encontrado con guiones reales (ej. "LAS TIERRAS INVISIBLES"):
# algunos PDFs con fuentes/kerning particulares hacen que pypdf inserte
# un espacio espurio justo DESPUÉS de una vocal acentuada o la "ñ" al
# extraer el texto — "MAÑANA" sale como "MAÑ ANA", "DÍA" como "DÍ A".
# En vez de intentar arreglar la extracción (no depende de nosotros),
# el patrón de cada palabra de momento tolera un espacio opcional justo
# después de cada letra acentuada, así "MAÑANA" y "MAÑ ANA" matchean
# igual sin arriesgar falsos positivos (dos letras separadas por un
# espacio real en mitad de otra palabra es un caso rarísimo).
_LETRAS_ACENTUADAS = "áéíóúñÁÉÍÓÚÑ"


def _patron_tolerante(palabra: str) -> str:
    partes = []
    for letra in palabra:
        partes.append(re.escape(letra))
        if letra in _LETRAS_ACENTUADAS:
            partes.append(r"\s*")
    return "".join(partes)


_MOMENTO_ALTERNATIVAS = "|".join(_patron_tolerante(w) for w in _MOMENTO_PALABRAS)

_MODO_VISTA_RE_PARTE = r"(INT\b\.?\s*/\s*EXT\b\.?|EXT\b\.?\s*/\s*INT\b\.?|INT\b\.?|EXT\b\.?)"

# Separadores vistos en guiones reales entre el lugar y el momento del
# día: guion normal, pero también guion largo/en-dash y raya/em-dash —
# muy comunes en PDFs exportados desde Word/Google Docs, que
# "autocorrigen" el guion simple a estos caracteres. El patrón anterior
# solo aceptaba "-" (ASCII) y por eso encabezados como "LAGUNA – DÍA"
# (con en-dash "–", U+2013) no se detectaban como escena: la búsqueda
# seguía expandiéndose hasta encontrar el PRIMER "-" ASCII varias
# escenas más adelante, tragándose todo el texto intermedio (escenas
# "perdidas" y encabezados gigantes con el texto de varias escenas
# pegado).
_GUION_RE_PARTE = r"[-‐‑‒–—]"

#
# BUG REAL encontrado en producción (guiones con portada/acotaciones
# que contienen palabras como "Extendida" o "Internacional"): la
# versión anterior de este patrón solo tenía un \b ANTES del grupo
# INT/EXT, nunca uno DESPUÉS de las 3 letras. Eso permitía que "Ext"
# dentro de "Extendida" o "Int" dentro de "Internacional" hicieran
# match como si fueran un encabezado real, y como el grupo(2) es
# no-codicioso pero solo se detiene en el PRIMER "- MOMENTO" que
# encuentre más adelante, el "encabezado" terminaba tragándose todo el
# texto de portada/acción intermedio hasta la escena real siguiente.
# Fix: exigir \b justo después de "INT"/"EXT" (antes del punto
# opcional), así "Ext" dentro de "Extendida" no cuenta como boundary
# (la "e" que sigue es letra, no hay corte de palabra ahí) pero
# "EXT." o "EXT " sí lo son.
_SCENE_RE = re.compile(
    # El prefijo "ESC"/"ESCENA" se exige en MAYÚSCULAS a propósito
    # (case-sensitive vía (?-i:...), aunque el resto del patrón use
    # IGNORECASE): en prosa normal es frecuentísimo terminar una
    # oración con la palabra "escena" en minúscula justo antes de un
    # encabezado real (ej. "...aumentando el misterio de la escena. 13.
    # INT. CUARTO...") — con el prefijo insensible a mayúsculas, ese
    # "escena." + número se leía como si fuera el marcador técnico de
    # número de escena y se tragaba el ". 13." de la oración anterior
    # dentro del encabezado detectado. Los guiones reales siempre
    # escriben este marcador en mayúsculas ("ESC 4.", "ESCENA 13."),
    # así que exigirlas elimina el falso positivo sin perder casos reales.
    r"\b(?:(?-i:ESC|ESCENA)\.?\s*\d+\.?\s*)?"
    r"\b" + _MODO_VISTA_RE_PARTE + r"\s*\.?\s*"
    # El lugar se acota a un máximo de 100 caracteres (en vez de un
    # "(.+?)" sin límite): un lugar de escena real nunca es tan largo, y
    # sin este tope, si el guion NO usa este formato en absoluto (ej. usa
    # el formato alterno de _SCENE_RE_ALT en todo el documento) y en
    # algún punto lejano del texto aparece por coincidencia un guion
    # seguido de una palabra de momento (ej. una acotación de transición
    # "TARDE-NOCHE"), el grupo no-codicioso se traga TODO el texto
    # intermedio -incluyendo escenas reales- en un solo "encabezado"
    # gigante (bug real visto con un guion de 100+ páginas).
    r"(.{1,100}?)\s*" + _GUION_RE_PARTE + r"\s*(" + _MOMENTO_ALTERNATIVAS + r")\b",
    re.IGNORECASE,
)

# Formato alterno visto en algunos guiones reales (ej. "LAS TIERRAS
# INVISIBLES"): el MOMENTO va justo después de INT/EXT, ANTES del
# lugar, sin ningún guion separador — "INT. NOCHE. CENTRO DE LA TIERRA"
# en vez de "INT. CENTRO DE LA TIERRA - NOCHE". Es una convención real
# y no un error de formato, así que necesita su propio patrón (no un
# simple cambio de orden en _SCENE_RE, porque ahí el lugar SÍ tiene un
# límite claro a la derecha: el guion antes del momento).
#
# Sin ese límite, ¿dónde termina el lugar en este formato? Los PDFs
# donde se vio esta convención (exportados de programas tipo
# Highland/Fade In) imprimen el número de escena duplicado justo ahí:
# pegado al final del lugar y otra vez separado por un espacio (ej.
# "...TIERRA1 1", "...FUNERAL. 2 2", y para escenas "insertadas" con
# sufijo de letra: "...EDIFICIO DE CIENCIAS 13A 13A") — se usa ese
# número (con su sufijo de letra opcional) repetido como límite natural
# del lugar, vía backreference (\d+[A-Za-z]?)\s+(?P=n).
_SCENE_RE_ALT = re.compile(
    r"\b" + _MODO_VISTA_RE_PARTE + r"\s*\.?\s*"
    r"(" + _MOMENTO_ALTERNATIVAS + r")\b\s*\.?\s*"
    # Mismo tope de 100 caracteres que en _SCENE_RE y por la misma razón
    # (evitar que, si el número duplicado que marca el final del lugar
    # no aparece cerca por algún motivo, el grupo se trague el resto del
    # documento buscándolo).
    r"(.{1,100}?)(?P<n>\d+[A-Za-z]?)\s+(?P=n)\b",
    re.IGNORECASE,
)

# Líneas/frases en mayúsculas que NO son nombres de personaje
# (encabezados de transición/técnicos comunes en guiones, o marcadores
# genéricos de sonido/voz-en-off que no identifican a un personaje real
# — "VOZ (OFF)" y variantes de "PENSAMIENTO" como acotación repetida se
# vieron en guiones reales generando falsos positivos). Se descartan
# como candidatos.
_NOT_A_CHARACTER = {
    "CORTE A", "FUNDIDO A NEGRO", "FADE IN", "FADE OUT", "TITULO", "TÍTULO",
    "CONTINUA", "CONTINÚA", "V.O.", "O.S.", "CONT'D", "FIN", "ESCENA",
    "TITULOS", "TÍTULOS", "CREDITOS", "CRÉDITOS", "VOZ", "VOZ EN OFF",
    "VOZ OFF", "PENSAMIENTO", "TERMINA SECUENCIA", "FIN DE SECUENCIA",
    "CONTINUARÁ", "CONTINUARA",
}

# Nombre de personaje (1 a 3 palabras en mayúsculas, con edad opcional
# entre paréntesis) seguido de su diálogo o una acotación — el
# indicador de "esto es un cue de personaje" es que venga justo al
# inicio del texto de la página o justo después del final de una
# oración (. ! ? o paréntesis de cierre), y que lo que sigue ya no
# esté en mayúsculas (el diálogo) o sea una acotación entre paréntesis.
_CHARACTER_CUE_RE = re.compile(
    r"(?:^|(?<=[.!?)]))\s*"
    r"([A-ZÁÉÍÓÚÑ]{2,}(?:\s[A-ZÁÉÍÓÚÑ]{2,}){0,2})"
    r"(?:\s*\(\d{1,3}\))?"
    r"\s+(?=[A-ZÁÉÍÓÚÑ][a-záéíóúñ]|\()"
)


def _normalize_modo_vista(raw: str) -> str | None:
    key = re.sub(r"\.", "", raw).strip().upper()
    key = re.sub(r"\s*/\s*", "/", key)
    return _MODO_VISTA_MAP.get(key)


def _normalize_momento_dia(raw: str) -> str | None:
    # El texto capturado puede traer un espacio espurio tolerado por
    # _patron_tolerante (ej. "MAÑ ANA" en vez de "MAÑANA") — se quita
    # TODO espacio interno antes de buscar en el catálogo, ya que
    # ninguna palabra de momento del día tiene espacios de verdad
    # (las combinadas como "DIA/NOCHE" ya se guardan sin espacios).
    key = re.sub(r"\s+", "", raw.strip().upper())
    return _MOMENTO_DIA_MAP.get(key)


def _normalize_whitespace(texto: str) -> str:
    return re.sub(r"\s+", " ", texto).strip()


def _extract_text_by_page(pdf_bytes: bytes) -> list[str]:
    reader = PdfReader(io.BytesIO(pdf_bytes))
    return [_normalize_whitespace(page.extract_text() or "") for page in reader.pages]


def _clean_character_name(nombre: str) -> str | None:
    nombre = nombre.strip()
    if nombre in _NOT_A_CHARACTER or len(nombre) < 2:
        return None
    palabras = nombre.split()
    if len(palabras) > 3:
        return None
    # Marcadores/acotaciones repetidas palabra-por-palabra (vistas en
    # guiones reales, ej. "PENSAMIENTO PENSAMIENTO" como convención de
    # formato para una voz interior) nunca son un nombre de personaje
    # real — un personaje no se llama a sí mismo dos veces seguidas.
    if len(palabras) > 1 and len(set(palabras)) == 1:
        return None
    return nombre


def _find_scene_matches(texto_completo: str) -> list[dict]:
    """
    Corre los dos formatos de encabezado soportados (_SCENE_RE:
    "LUGAR - MOMENTO", y _SCENE_RE_ALT: "MOMENTO. LUGAR") sobre el
    mismo texto y combina los resultados en una sola lista ordenada por
    posición, cada uno normalizado a
    {"start", "end", "modo_raw", "momento_raw", "encabezado"}.

    Si ambos patrones matchean el mismo tramo de texto (no debería pasar
    en un guion con un solo formato, pero por seguridad ante guiones con
    formato mixto o falsos positivos cruzados), se descarta el que
    empieza después, quedándose con el primero encontrado en esa
    posición.
    """
    encontrados: list[dict] = []

    for m in _SCENE_RE.finditer(texto_completo):
        encontrados.append({
            "start": m.start(),
            "end": m.end(),
            "modo_raw": m.group(1),
            "momento_raw": m.group(3),
            "encabezado": _normalize_whitespace(m.group(0)),
        })

    for m in _SCENE_RE_ALT.finditer(texto_completo):
        # El encabezado se reconstruye a partir del texto crudo
        # matcheado, quitando el número de escena duplicado del final
        # (ej. "...TIERRA1 1" -> "...TIERRA") y cualquier punto/espacio
        # colgante que quede tras cortarlo.
        crudo = m.group(0)
        crudo_sin_numero = re.sub(r"\d+[A-Za-z]?\s+\d+[A-Za-z]?\s*$", "", crudo)
        encontrados.append({
            "start": m.start(),
            "end": m.end(),
            "modo_raw": m.group(1),
            "momento_raw": m.group(2),
            "encabezado": _normalize_whitespace(crudo_sin_numero).rstrip(" ."),
        })

    # Al empatar en la posición de inicio (los dos patrones detectan el
    # mismo encabezado), se prioriza el match MÁS CORTO: si uno de los
    # dos se extendió de más buscando su terminador (guion+momento o
    # número duplicado) y no lo encontró cerca, es casi seguro el que
    # está mal, así que se descarta en vez de tragarse texto de más.
    encontrados.sort(key=lambda e: (e["start"], e["end"]))

    combinados: list[dict] = []
    for entrada in encontrados:
        if combinados and entrada["start"] < combinados[-1]["end"]:
            continue  # se solapa con uno ya aceptado, se descarta
        combinados.append(entrada)

    return combinados


def parse_script(pdf_bytes: bytes) -> dict:
    """
    Devuelve:
    {
        "escenas": [
            {
                "numero_de_escena": "1",
                "encabezado": "EXT. CARRERA SÉPTIMA / CALLES DEL CENTRO - DÍA",
                "modo_vista": "ext" | None,
                "momento_dia": "dia" | None,
                "pagina": 1,
                "personajes_detectados": ["JULIÁN", "ELENA"],
            },
            ...
        ],
        "personajes_detectados": ["JULIÁN", "ELENA", "CONDUCTOR"],
    }
    """
    paginas = _extract_text_by_page(pdf_bytes)

    # Se concatena todo el documento en un solo texto continuo (en vez
    # de procesar página por página) porque una escena puede empezar
    # en una página y su diálogo/acción seguir en la siguiente — cortar
    # por página perdería esos personajes. Se guarda el offset donde
    # empieza cada página para poder reportar en qué página cae cada
    # escena detectada.
    texto_completo = ""
    offsets_pagina: list[tuple[int, int]] = []  # (offset_inicio, numero_pagina)
    for idx_pagina, texto in enumerate(paginas, start=1):
        offsets_pagina.append((len(texto_completo), idx_pagina))
        texto_completo += texto + " "

    def _pagina_de(pos: int) -> int:
        pagina = 1
        for offset, idx_pagina in offsets_pagina:
            if pos >= offset:
                pagina = idx_pagina
            else:
                break
        return pagina

    matches = _find_scene_matches(texto_completo)

    # Primera pasada: contar apariciones de cada personaje candidato en
    # TODO el guion, para descartar palabras en mayúsculas que
    # aparecieron una sola vez (falsos positivos de acción, no
    # personajes reales con diálogo).
    candidatos_conteo: dict[str, int] = {}
    for cm in _CHARACTER_CUE_RE.finditer(texto_completo):
        nombre = _clean_character_name(cm.group(1))
        if nombre:
            candidatos_conteo[nombre] = candidatos_conteo.get(nombre, 0) + 1

    personajes_validos = {nombre for nombre, veces in candidatos_conteo.items() if veces >= 2}

    escenas = []
    personajes_globales: "OrderedDict[str, None]" = OrderedDict()

    for idx, m in enumerate(matches):
        numero = idx + 1
        modo_vista = _normalize_modo_vista(m["modo_raw"])
        momento_dia = _normalize_momento_dia(m["momento_raw"])
        encabezado_limpio = m["encabezado"]

        # Personajes de esta escena: los que aparecen entre el final de
        # este encabezado y el inicio del siguiente (o el final del
        # documento, si es la última escena).
        inicio_fragmento = m["end"]
        fin_fragmento = matches[idx + 1]["start"] if idx + 1 < len(matches) else len(texto_completo)
        fragmento = texto_completo[inicio_fragmento:fin_fragmento]

        personajes_escena: "OrderedDict[str, None]" = OrderedDict()
        for cm in _CHARACTER_CUE_RE.finditer(fragmento):
            nombre = _clean_character_name(cm.group(1))
            if nombre and nombre in personajes_validos:
                personajes_escena[nombre] = None
                personajes_globales[nombre] = None

        escenas.append({
            "numero_de_escena": str(numero),
            "encabezado": encabezado_limpio,
            "modo_vista": modo_vista,
            "momento_dia": momento_dia,
            "pagina": _pagina_de(m["start"]),
            "personajes_detectados": list(personajes_escena.keys()),
        })

    return {
        "escenas": escenas,
        "personajes_detectados": list(personajes_globales.keys()),
    }
