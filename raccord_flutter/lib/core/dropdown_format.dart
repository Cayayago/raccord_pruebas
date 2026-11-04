/// Formato de VISTA para listas desplegables: orden alfabético y primera
/// letra en mayúscula. No toca los valores que se guardan en la base de
/// datos (solo cambia lo que se ve y el orden en que se ofrece).

/// Primera letra en mayúscula; el resto del texto queda igual para no
/// dañar siglas (INT, EXT, DNI...) ni nombres propios.
String capitalizeFirst(String s) {
  final t = s.trimLeft();
  if (t.isEmpty) return s;
  return t[0].toUpperCase() + t.substring(1);
}

const _acentos = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
};

String _clave(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_acentos[ch] ?? ch);
  }
  return b.toString().trim();
}

/// Opciones "comodín" que deben quedar de primeras aunque no sean las
/// primeras alfabéticamente (Todos, Todas, Ninguno, Sin asignar...).
bool _esComodin(String s) {
  final k = _clave(s);
  return k.startsWith('todo') ||
      k.startsWith('toda') ||
      k.startsWith('ninguno') ||
      k.startsWith('ninguna') ||
      k.startsWith('sin ') ||
      k.startsWith('seleccion') ||
      k.startsWith('predeterminado');
}

/// Comparación alfabética sin distinguir mayúsculas ni tildes, y "natural":
/// "Bloque 2" va antes que "Bloque 10".
int compareAlpha(String a, String b) {
  final x = _clave(a), y = _clave(b);
  final re = RegExp(r'(\d+)|(\D+)');
  final pa = re.allMatches(x).map((m) => m.group(0)!).toList();
  final pb = re.allMatches(y).map((m) => m.group(0)!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final sa = pa[i], sb = pb[i];
    final na = int.tryParse(sa), nb = int.tryParse(sb);
    final c = (na != null && nb != null) ? na.compareTo(nb) : sa.compareTo(sb);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

/// Devuelve una copia ordenada alfabéticamente (por la etiqueta visible),
/// dejando primero los comodines tipo "Todos" / "Sin asignar".
List<T> sortedAlpha<T>(Iterable<T> items, String Function(T) label) {
  final lista = items.toList();
  lista.sort((a, b) {
    final la = label(a), lb = label(b);
    final wa = _esComodin(la), wb = _esComodin(lb);
    if (wa != wb) return wa ? -1 : 1;
    return compareAlpha(la, lb);
  });
  return lista;
}
