import 'dart:convert';

import 'package:csv/csv.dart' as csv_pkg;
import 'package:file_picker/file_picker.dart';

/// Utilidad compartida de "Carga masiva" (CSV/JSON) para escenas,
/// personajes, actores y roles (invitaciones). Cada pantalla define su
/// propio mapeo de columnas -> campos del modelo; esta función solo se
/// encarga de la parte genérica: elegir el archivo, detectar el
/// formato por extensión, y devolver una lista de filas como
/// Map<String, String> con las llaves normalizadas (minúsculas, sin
/// espacios sobrantes) tal como vienen en la fila de encabezado.
///
/// NOTA: no se soporta .xlsx a propósito. El paquete "excel" exige
/// archive ^3.x y "pdfrx" (visor de PDF) exige archive ^4.x en TODAS
/// sus versiones — no hay combinación posible de ambos en el mismo
/// proyecto. Como pdfrx ya reemplazó a Syncfusion por bugs reales de
/// visualización, se prioriza mantenerlo. Para Excel, exportar la hoja
/// a CSV antes de subirla.
///
/// Devuelve `null` si la persona cancela el selector de archivos.
Future<List<Map<String, String>>?> pickAndParseBulkFile() async {
  // file_picker 13.x: pickFile() (singular) reemplaza al viejo patrón
  // pickFiles(...).files.single — devuelve el PlatformFile directo (o
  // null si se cancela), sin el wrapper FilePickerResult. withData ya
  // no existe: los bytes se piden aparte, siempre async, con
  // readAsBytes() (ver abajo) — funciona igual en Web que en nativo.
  final picked = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['csv', 'json'],
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final nombre = picked.name.toLowerCase();

  if (nombre.endsWith('.json')) {
    return _parseJson(utf8.decode(bytes));
  }
  if (nombre.endsWith('.csv')) {
    return _parseCsv(utf8.decode(bytes));
  }

  throw Exception('Formato no soportado. Usa un archivo .csv o .json (Excel: expórtalo a CSV primero).');
}

String _normalizeKey(String key) => key.trim().toLowerCase();

List<Map<String, String>> _parseJson(String content) {
  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw Exception('El archivo JSON debe contener una lista de objetos (uno por fila)');
  }
  return decoded.map<Map<String, String>>((item) {
    if (item is! Map) {
      throw Exception('Cada elemento del JSON debe ser un objeto (ej. {"nombre": "..."})');
    }
    return item.map((key, value) => MapEntry(_normalizeKey(key.toString()), value?.toString() ?? ''));
  }).toList();
}

List<Map<String, String>> _parseCsv(String content) {
  // API de csv v8: `csv` es una instancia por defecto ya lista para
  // usar (ver package:csv/csv.dart) — csv.decode() devuelve todas las
  // filas de una vez como List<List<dynamic>>, la primera es el
  // encabezado.
  final rows = csv_pkg.csv.decode(content);
  if (rows.isEmpty) return [];

  final headers = rows.first.map((h) => _normalizeKey(h.toString())).toList();
  final dataRows = rows.skip(1).where((r) => r.any((cell) => cell.toString().trim().isNotEmpty));

  return dataRows.map((row) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length; i++) {
      map[headers[i]] = i < row.length ? row[i].toString() : '';
    }
    return map;
  }).toList();
}

/// Resultado de procesar fila por fila un archivo de carga masiva —
/// cada pantalla arma esta lista mientras crea sus registros, y
/// [showBulkResultDialog] la muestra en un resumen simple.
class BulkRowResult {
  final int fila; // 1-based, sin contar el encabezado
  final bool ok;
  final String detalle;
  BulkRowResult({required this.fila, required this.ok, required this.detalle});
}
