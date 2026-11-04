import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Lectura y escritura mínima de archivos Excel (.xlsx) para la carga
/// masiva, SIN el paquete "excel" (choca con pdfrx por la versión de
/// "archive"). Un .xlsx es un .zip con XML adentro:
///  - escritura: se arma el zip a mano (sin compresión) -> no depende de
///    la API de escritura de "archive";
///  - lectura: se abre con ZipDecoder (archive) y se interpreta el XML
///    de la primera hoja con "xml".

/// Una hoja a escribir. La fila 0 es el encabezado (con estilo).
class XlsxSheet {
  final String name;
  final List<List<String>> rows;

  /// Ancho de cada columna (en caracteres). Si es null se calcula.
  final List<double>? widths;

  /// Listas desplegables por columna (índice -> opciones). Se aplican a
  /// las filas 2..1000.
  final Map<int, List<String>> dropdowns;

  /// true: las celdas de datos se guardan como TEXTO (evita que Excel
  /// convierta "0012" en 12 o una fecha en número).
  final bool textCells;

  /// true: el texto largo se ajusta a la celda (hoja de instrucciones).
  final bool wrapBody;

  const XlsxSheet({
    required this.name,
    required this.rows,
    this.widths,
    this.dropdowns = const {},
    this.textCells = true,
    this.wrapBody = false,
  });
}

// ---------------------------------------------------------------------
// ESCRITURA
// ---------------------------------------------------------------------

Uint8List buildXlsx(List<XlsxSheet> sheets) {
  final files = <String, List<int>>{};
  List<int> u(String s) => utf8.encode(s);

  files['[Content_Types].xml'] = u('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '${[for (var i = 0; i < sheets.length; i++) '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
      '</Types>');

  files['_rels/.rels'] = u('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>');

  files['xl/workbook.xml'] = u('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
      '${[for (var i = 0; i < sheets.length; i++) '<sheet name="${_esc(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
      '</sheets></workbook>');

  files['xl/_rels/workbook.xml.rels'] = u('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '${[for (var i = 0; i < sheets.length; i++) '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'].join()}'
      '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>');

  // Estilos: 0 normal, 1 texto, 2 encabezado (azul Raccord, blanco,
  // negrita), 3 texto con ajuste de línea.
  files['xl/styles.xml'] = u('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>'
      '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF0B4F8A"/><bgColor indexed="64"/></patternFill></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="4">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="49" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
      '<xf numFmtId="49" fontId="1" fillId="2" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyAlignment="1">'
      '<alignment wrapText="1" vertical="center"/></xf>'
      '<xf numFmtId="49" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1">'
      '<alignment wrapText="1" vertical="top"/></xf>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>');

  for (var i = 0; i < sheets.length; i++) {
    files['xl/worksheets/sheet${i + 1}.xml'] = u(_sheetXml(sheets[i]));
  }

  return _zipStored(files);
}

String _sheetXml(XlsxSheet sh) {
  final cols = sh.rows.isEmpty ? 0 : sh.rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  final bodyStyle = sh.wrapBody ? 3 : (sh.textCells ? 1 : 0);

  final buf = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0">'
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>');

  // Ancho y estilo por columna (así las celdas vacías que la persona
  // llene después también quedan como texto).
  buf.write('<cols>');
  for (var c = 0; c < cols; c++) {
    var w = sh.widths != null && c < sh.widths!.length ? sh.widths![c] : 0.0;
    if (w == 0) {
      final len = sh.rows.isNotEmpty && c < sh.rows.first.length ? sh.rows.first[c].length : 12;
      w = (len * 0.9).clamp(16, 42).toDouble();
    }
    buf.write('<col min="${c + 1}" max="${c + 1}" width="$w" style="$bodyStyle" customWidth="1"/>');
  }
  buf.write('</cols><sheetData>');

  for (var r = 0; r < sh.rows.length; r++) {
    final isHeader = r == 0;
    buf.write(isHeader ? '<row r="1" ht="62" customHeight="1">' : '<row r="${r + 1}">');
    for (var c = 0; c < sh.rows[r].length; c++) {
      final ref = '${_colLetters(c)}${r + 1}';
      final style = isHeader ? 2 : bodyStyle;
      buf.write('<c r="$ref" s="$style" t="inlineStr"><is><t xml:space="preserve">${_esc(sh.rows[r][c])}</t></is></c>');
    }
    buf.write('</row>');
  }
  buf.write('</sheetData>');

  final validos = sh.dropdowns.entries.where((e) => e.value.isNotEmpty && e.value.join(',').length <= 250).toList();
  if (validos.isNotEmpty) {
    buf.write('<dataValidations count="${validos.length}">');
    for (final e in validos) {
      final col = _colLetters(e.key);
      buf.write('<dataValidation type="list" allowBlank="1" showErrorMessage="1" '
          'errorTitle="Valor no permitido" error="Elige un valor de la lista." sqref="${col}2:${col}1000">'
          '<formula1>"${_esc(e.value.join(','))}"</formula1></dataValidation>');
    }
    buf.write('</dataValidations>');
  }

  buf.write('</worksheet>');
  return buf.toString();
}

String _colLetters(int index) {
  var n = index + 1;
  var s = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ZIP sin compresión ("stored"): válido para Excel y sin depender de la
// API de escritura de "archive".
Uint8List _zipStored(Map<String, List<int>> files) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  var count = 0;

  void u16(BytesBuilder b, int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);
  void u32(BytesBuilder b, int v) => b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

  files.forEach((name, data) {
    final nameBytes = utf8.encode(name);
    final crc = _crc32(data);
    final offset = out.length;

    u32(out, 0x04034b50);
    u16(out, 20); // versión mínima
    u16(out, 0x0800); // nombres en UTF-8
    u16(out, 0); // sin compresión
    u16(out, 0); // hora
    u16(out, 0x21); // fecha (1980-01-01)
    u32(out, crc);
    u32(out, data.length);
    u32(out, data.length);
    u16(out, nameBytes.length);
    u16(out, 0);
    out.add(nameBytes);
    out.add(data);

    u32(central, 0x02014b50);
    u16(central, 20);
    u16(central, 20);
    u16(central, 0x0800);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0x21);
    u32(central, crc);
    u32(central, data.length);
    u32(central, data.length);
    u16(central, nameBytes.length);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u32(central, 0);
    u32(central, offset);
    central.add(nameBytes);
    count++;
  });

  final centralStart = out.length;
  final centralBytes = central.toBytes();
  out.add(centralBytes);

  u32(out, 0x06054b50);
  u16(out, 0);
  u16(out, 0);
  u16(out, count);
  u16(out, count);
  u32(out, centralBytes.length);
  u32(out, centralStart);
  u16(out, 0);

  return out.toBytes();
}

final List<int> _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    t[n] = c;
  }
  return t;
}();

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

// ---------------------------------------------------------------------
// LECTURA
// ---------------------------------------------------------------------

/// Devuelve las filas de la PRIMERA hoja como listas de texto (la fila 0
/// es el encabezado). Lanza una excepción legible si el archivo no es un
/// Excel válido.
List<List<String>> readXlsxRows(List<int> bytes) {
  final Archive zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw Exception('El archivo .xlsx no se pudo abrir (¿está dañado o protegido con contraseña?).');
  }

  ArchiveFile? find(String name) {
    for (final f in zip.files) {
      if (f.name == name) return f;
    }
    return null;
  }

  String text(ArchiveFile f) => utf8.decode(f.content as List<int>, allowMalformed: true);

  // Textos compartidos (Excel guarda ahí casi todo el texto).
  final shared = <String>[];
  final ss = find('xl/sharedStrings.xml');
  if (ss != null) {
    final doc = XmlDocument.parse(text(ss));
    for (final si in doc.findAllElements('si')) {
      shared.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }

  // Primera hoja: sheet1.xml si existe; si no, la primera por nombre.
  ArchiveFile? sheet = find('xl/worksheets/sheet1.xml');
  if (sheet == null) {
    final candidatas = zip.files.where((f) => f.name.startsWith('xl/worksheets/') && f.name.endsWith('.xml')).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (candidatas.isNotEmpty) sheet = candidatas.first;
  }
  if (sheet == null) throw Exception('El archivo .xlsx no tiene hojas.');

  final doc = XmlDocument.parse(text(sheet));
  final filas = <int, Map<int, String>>{};
  var maxCol = 0;
  var maxRow = 0;

  for (final c in doc.findAllElements('c')) {
    final ref = c.getAttribute('r') ?? '';
    final m = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref);
    if (m == null) continue;
    final col = _colIndex(m.group(1)!);
    final row = int.parse(m.group(2)!) - 1;
    final tipo = c.getAttribute('t');

    String valor = '';
    if (tipo == 'inlineStr') {
      valor = c.findAllElements('t').map((t) => t.innerText).join();
    } else {
      final v = c.getElement('v')?.innerText ?? '';
      if (tipo == 's') {
        final idx = int.tryParse(v);
        valor = idx != null && idx < shared.length ? shared[idx] : '';
      } else if (tipo == 'b') {
        valor = v == '1' ? 'sí' : 'no';
      } else {
        valor = v; // número, fecha (serial) o texto de fórmula
        if (RegExp(r'^-?\d+\.0+$').hasMatch(valor)) valor = valor.split('.').first;
      }
    }

    (filas[row] ??= {})[col] = valor;
    if (col + 1 > maxCol) maxCol = col + 1;
    if (row + 1 > maxRow) maxRow = row + 1;
  }

  return [
    for (var r = 0; r < maxRow; r++)
      [for (var c = 0; c < maxCol; c++) filas[r]?[c] ?? ''],
  ];
}

int _colIndex(String letters) {
  var n = 0;
  for (final ch in letters.codeUnits) {
    n = n * 26 + (ch - 64);
  }
  return n - 1;
}
