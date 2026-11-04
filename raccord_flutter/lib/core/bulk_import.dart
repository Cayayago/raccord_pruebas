import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import 'xlsx_io.dart';

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
    allowedExtensions: ['xlsx', 'csv', 'json'],
  );
  if (picked == null) return null;

  return parseBulkBytes(picked.name, await picked.readAsBytes());
}

/// Convierte el contenido de un archivo .csv/.json en filas (llaves en
/// minúsculas). Lanza una excepción con mensaje legible si el formato no
/// es válido.
List<Map<String, String>> parseBulkBytes(String nombreArchivo, List<int> bytes) {
  final nombre = nombreArchivo.toLowerCase();

  // Excel: se lee con xlsx_io.dart (zip + xml, sin el paquete "excel").
  if (nombre.endsWith('.xlsx')) return _parseTabla(readXlsxRows(bytes));
  // utf8.decode con allowMalformed y sin BOM: Excel guarda los CSV en UTF-8
  // con BOM ("\uFEFF") y eso se pegaba al primer encabezado.
  var texto = utf8.decode(bytes, allowMalformed: true);
  if (texto.startsWith('\uFEFF')) texto = texto.substring(1);

  if (nombre.endsWith('.json')) return _parseJson(texto);
  if (nombre.endsWith('.csv')) return _parseCsv(texto);

  throw Exception('Formato no soportado. Usa un archivo Excel (.xlsx), .csv o .json.');
}

/// Guarda un archivo Excel (.xlsx) con el selector "Guardar como".
Future<bool> saveXlsxFile({required String fileName, required Uint8List bytes}) async {
  final path = await FileSaver.instance.saveAs(
    name: fileName,
    bytes: bytes,
    fileExtension: 'xlsx',
    mimeType: MimeType.microsoftExcel,
  );
  return path != null;
}

/// Normaliza un título de columna: quita lo que va entre paréntesis (las
/// opciones de ayuda, ej. "Rol (Administrador, Director)"), el asterisco
/// de obligatorio, espacios sobrantes y pasa a minúsculas.
String normalizeHeader(String key) {
  var k = key.trim();
  k = k.replaceAll(RegExp(r'\s*\(.*\)\s*$', dotAll: true), '');
  k = k.replaceAll(RegExp(r'\s*\*+\s*$'), '');
  return k.trim().toLowerCase();
}

/// Texto "plegado" para comparar sin importar tildes, mayúsculas ni
/// separadores (espacios, guion bajo, barra): "Área / Departamento" ==
/// "area_departamento".
String foldText(String s) {
  const de = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const a = 'aaaaaeeeeiiiiooooouuuun';
  final buf = StringBuffer();
  for (final ch in s.trim().toLowerCase().split('')) {
    final i = de.indexOf(ch);
    buf.write(i >= 0 ? a[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'[\s_/\-\.]+'), ' ').trim();
}

List<Map<String, String>> _parseTabla(List<List<String>> rows) {
  if (rows.isEmpty) return [];
  final headers = rows.first.map(normalizeHeader).toList();
  final data = rows.skip(1).where((r) => r.any((c) => c.trim().isNotEmpty));
  return data.map((row) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].isEmpty) continue;
      map[headers[i]] = i < row.length ? row[i].trim() : '';
    }
    return map;
  }).toList();
}

/// Guarda un CSV (con BOM para que Excel respete tildes y eñes) usando el
/// selector "Guardar como". Devuelve true si se guardó.
Future<bool> saveCsvFile({
  required String fileName,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  final contenido = csv_pkg.csv.encode([headers, ...rows]);
  final bytes = Uint8List.fromList(utf8.encode('\uFEFF$contenido'));
  final path = await FileSaver.instance.saveAs(
    name: fileName,
    bytes: bytes,
    fileExtension: 'csv',
    mimeType: MimeType.csv,
  );
  return path != null;
}

String _normalizeKey(String key) => normalizeHeader(key);

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
