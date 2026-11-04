const _mesesEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

/// Formato "d MMM y" en español sin depender de datos de localización
/// de `intl` (que requieren inicialización asíncrona) — evita fallos en
/// tiempo de ejecución si la app arranca antes de cargarlos.
String formatDateEs(DateTime date) {
  return '${date.day} ${_mesesEs[date.month - 1]} ${date.year}';
}

String formatTimeOfDay(String? hhmmss) {
  if (hhmmss == null || hhmmss.isEmpty) return '';
  final parts = hhmmss.split(':');
  if (parts.length < 2) return hhmmss;
  return '${parts[0]}:${parts[1]}';
}
