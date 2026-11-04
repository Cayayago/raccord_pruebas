import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/bulk_import.dart';
import '../core/responsive.dart';
import '../core/xlsx_io.dart';
import '../theme/app_theme.dart';

/// Plantilla de una carga masiva: define qué columnas lleva el archivo,
/// un ejemplo y cuáles son obligatorias. Con esto se arma el botón
/// "Descargar plantilla" y la validación previa de cada fila.
class BulkTemplate {
  /// Nombre en plural para el título ("escenas", "personajes"...).
  final String entidad;

  /// Nombre del archivo de la plantilla, sin extensión.
  final String fileName;

  /// Títulos de columna tal como los espera el sistema.
  final List<String> headers;

  /// Una fila de ejemplo (misma cantidad de valores que [headers]).
  final List<String> example;

  /// Columnas obligatorias. Cada grupo es una lista de nombres
  /// equivalentes (alias): basta que venga con valor uno del grupo.
  final List<List<String>> required;

  /// Título amigable de cada columna (llave interna -> texto que ve la
  /// persona en el Excel, ej. 'modo_vista' -> 'Modo de vista'). Si falta,
  /// se genera a partir de la llave ("fecha_de_nacimiento" ->
  /// "Fecha de nacimiento").
  final Map<String, String> labels;

  /// Valores permitidos de las columnas de datos fijos (llave -> opciones).
  /// Se muestran entre paréntesis en el título y como lista desplegable.
  final Map<String, List<String>> options;

  const BulkTemplate({
    required this.entidad,
    required this.fileName,
    required this.headers,
    required this.example,
    required this.required,
    this.labels = const {},
    this.options = const {},
  });

  bool isRequired(String key) => required.any((g) => g.contains(key));

  String label(String key) {
    final l = labels[key];
    if (l != null) return l;
    final t = key.replaceAll('_', ' ').trim();
    return t.isEmpty ? key : t[0].toUpperCase() + t.substring(1);
  }

  /// Título que va en el Excel: "Rol * (Administrador, Director)".
  String displayHeader(String key) {
    final op = options[key];
    final base = isRequired(key) ? '${label(key)} *' : label(key);
    return op == null || op.isEmpty ? base : '$base (${op.join(', ')})';
  }

  /// Convierte las filas leídas (con los títulos que haya escrito la
  /// persona) al formato interno: títulos -> llaves del sistema, valores
  /// de datos fijos -> forma canónica (sin importar tildes/mayúsculas) y
  /// fechas seriales de Excel -> yyyy-mm-dd.
  List<Map<String, String>> convertir(List<Map<String, String>> rows) {
    final porTitulo = <String, String>{};
    for (final k in headers) {
      porTitulo[foldText(k)] = k;
      porTitulo[foldText(label(k))] = k;
    }
    // Alias de "required" (ej. 'correo', 'email') también apuntan a la
    // llave principal del grupo.
    for (final g in required) {
      for (final a in g) {
        porTitulo.putIfAbsent(foldText(a), () => g.first);
      }
    }

    return [
      for (final row in rows)
        () {
          final out = <String, String>{};
          row.forEach((k, v) {
            final key = porTitulo[foldText(k)] ?? k;
            var valor = v.trim();
            final op = options[key];
            if (op != null && valor.isNotEmpty) {
              final f = foldText(valor);
              for (final o in op) {
                if (foldText(o) == f) {
                  valor = o;
                  break;
                }
              }
            }
            if (key.contains('fecha') && RegExp(r'^\d{4,6}(\.\d+)?$').hasMatch(valor)) {
              final serial = double.parse(valor);
              if (serial > 20000 && serial < 80000) {
                final d = DateTime.utc(1899, 12, 30).add(Duration(days: serial.floor()));
                valor = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              }
            }
            out[key] = valor;
          });
          return out;
        }(),
    ];
  }
}

/// Botón "Carga masiva" reutilizable (escenas, personajes, cast list,
/// crew list y roles). Al tocarlo abre una ventana con:
///  - una barra para buscar el archivo (.csv/.json) en el equipo,
///  - el botón "Descargar plantilla" con los títulos exactos,
///  - el botón "Cargar", que primero VALIDA todas las filas, guarda las
///    correctas y devuelve las que tienen error (con el motivo) en un
///    CSV listo para corregir y volver a subir.
///
/// [onRows] guarda las filas válidas que le entrega el diálogo (cada
/// fila trae '__fila' con su número en el archivo original). [validateRow]
/// es opcional: validaciones propias de cada pantalla (valores
/// permitidos, formatos...) que se suman a la de columnas obligatorias.
/// [onDone] se llama al cerrar si se cargó algo, para refrescar la lista.
class BulkUploadButton extends StatelessWidget {
  final BulkTemplate template;
  final Future<List<BulkRowResult>> Function(List<Map<String, String>> rows) onRows;
  final String? Function(Map<String, String> row)? validateRow;
  final VoidCallback? onDone;

  const BulkUploadButton({
    super.key,
    required this.template,
    required this.onRows,
    this.validateRow,
    this.onDone,
  });

  Future<void> _open(BuildContext context) async {
    final cambio = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkUploadDialog(template: template, onRows: onRows, validateRow: validateRow),
    );
    if (cambio == true) onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.upload_file_outlined, size: 18);

    // En móvil/tablet angosto el texto desbordaba el AppBar: se colapsa a
    // un ícono solo (con tooltip), igual que el resto de acciones.
    if (isMobileScreen(context)) {
      return IconButton(
        onPressed: () => _open(context),
        icon: icon,
        tooltip: 'Carga masiva',
        style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline)),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: icon,
      label: const Text('Carga masiva'),
    );
  }
}

class _BulkUploadDialog extends StatefulWidget {
  final BulkTemplate template;
  final Future<List<BulkRowResult>> Function(List<Map<String, String>> rows) onRows;
  final String? Function(Map<String, String> row)? validateRow;

  const _BulkUploadDialog({required this.template, required this.onRows, this.validateRow});

  @override
  State<_BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkReport {
  final int total;
  final int cargadas;
  final List<_BulkError> errores;
  _BulkReport({required this.total, required this.cargadas, required this.errores});
}

class _BulkError {
  final int fila;
  final String motivo;
  final Map<String, String> datos;
  _BulkError(this.fila, this.motivo, this.datos);
}

class _BulkUploadDialogState extends State<_BulkUploadDialog> {
  String? _nombreArchivo;
  List<Map<String, String>>? _rows;
  String? _errorArchivo;
  bool _cargando = false;
  _BulkReport? _report;
  bool _huboCambios = false;

  BulkTemplate get _t => widget.template;

  Future<void> _elegirArchivo() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'json'],
      );
      if (picked == null) return; // canceló el selector

      final rows = _t.convertir(parseBulkBytes(picked.name, await picked.readAsBytes()));
      setState(() {
        _nombreArchivo = picked.name;
        _rows = rows;
        _report = null;
        _errorArchivo = rows.isEmpty ? 'El archivo no tiene filas de datos (solo encabezado o está vacío).' : null;
      });
    } catch (e) {
      setState(() {
        _nombreArchivo = null;
        _rows = null;
        _report = null;
        _errorArchivo = 'No se pudo leer el archivo: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  String? _valor(Map<String, String> row, List<String> alias) {
    for (final k in alias) {
      final v = row[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Validación previa de una fila (sin escribir nada): columnas
  /// obligatorias y, si la pantalla lo definió, sus reglas propias.
  String? _validar(Map<String, String> row) {
    final faltan = [
      for (final grupo in _t.required)
        if (_valor(row, grupo) == null) grupo.first,
    ];
    if (faltan.isNotEmpty) return 'Falta(n): ${faltan.join(', ')}';
    return widget.validateRow?.call(row);
  }

  Future<void> _cargar() async {
    final rows = _rows;
    if (rows == null || rows.isEmpty) return;
    setState(() => _cargando = true);

    try {
      final errores = <int, String>{};
      final validas = <Map<String, String>>[];

      for (var i = 0; i < rows.length; i++) {
        final fila = i + 2; // fila 1 = encabezado del archivo
        final motivo = _validar(rows[i]);
        if (motivo != null) {
          errores[fila] = motivo;
        } else {
          validas.add({...rows[i], '__fila': '$fila'});
        }
      }

      var cargadas = 0;
      if (validas.isNotEmpty) {
        final resultados = await widget.onRows(validas);
        for (final r in resultados) {
          if (r.ok) {
            cargadas++;
          } else {
            errores[r.fila] = r.detalle;
          }
        }
      }

      final lista = errores.keys.toList()..sort();
      setState(() {
        _report = _BulkReport(
          total: rows.length,
          cargadas: cargadas,
          errores: [for (final f in lista) _BulkError(f, errores[f]!, rows[f - 2])],
        );
        if (cargadas > 0) _huboCambios = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo procesar el archivo: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _descargarPlantilla() async {
    // Hoja 1 "Plantilla": una columna por atributo, con ejemplo.
    // Hoja 2 "Instrucciones": qué lleva cada columna y sus opciones.
    final instrucciones = <List<String>>[
      ['Columna', 'Obligatoria', 'Qué escribir'],
      for (final k in _t.headers)
        [
          _t.label(k),
          _t.isRequired(k) ? 'Sí' : 'No',
          (_t.options[k] ?? const []).isNotEmpty
              ? 'Elige una opción: ${_t.options[k]!.join(', ')}'
              : 'Texto libre (ej. ${_t.example[_t.headers.indexOf(k)].isEmpty ? '—' : _t.example[_t.headers.indexOf(k)]})',
        ],
    ];
    final bytes = buildXlsx([
      XlsxSheet(
        name: 'Plantilla',
        rows: [
          [for (final k in _t.headers) _t.displayHeader(k)],
          _t.example,
        ],
        dropdowns: {
          for (var i = 0; i < _t.headers.length; i++)
            if ((_t.options[_t.headers[i]] ?? const []).isNotEmpty) i: _t.options[_t.headers[i]]!,
        },
      ),
      XlsxSheet(
        name: 'Instrucciones',
        rows: instrucciones,
        widths: const [28, 14, 80],
        wrapBody: true,
      ),
    ]);
    final ok = await saveXlsxFile(fileName: _t.fileName, bytes: bytes);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantilla guardada correctamente')));
    }
  }

  Future<void> _descargarErrores() async {
    final report = _report;
    if (report == null || report.errores.isEmpty) return;

    // Mismas columnas del archivo original + "error": se corrige y se
    // vuelve a subir tal cual (la columna "error" se ignora al cargar).
    // Columnas de la plantilla (con sus títulos amigables) + las extra
    // que traiga el archivo, y al final "Error".
    final extras = _rows!.first.keys.where((k) => k != '__fila' && !_t.headers.contains(k)).toList();
    final llaves = [..._t.headers, ...extras];
    final bytes = buildXlsx([
      XlsxSheet(
        name: 'Filas con error',
        rows: [
          [for (final k in llaves) _t.headers.contains(k) ? _t.displayHeader(k) : k, 'Error'],
          for (final e in report.errores) [for (final k in llaves) e.datos[k] ?? '', e.motivo],
        ],
        dropdowns: {
          for (var i = 0; i < _t.headers.length; i++)
            if ((_t.options[_t.headers[i]] ?? const []).isNotEmpty) i: _t.options[_t.headers[i]]!,
        },
      ),
    ]);
    final ok = await saveXlsxFile(fileName: '${_t.fileName}_con_errores', bytes: bytes);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archivo con errores guardado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final puedeCargar = _rows != null && _rows!.isNotEmpty && !_cargando && report == null;

    return AlertDialog(
      title: Text('Carga masiva de ${_t.entidad}'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descarga la plantilla, llénala y súbela. Se revisan todas las filas: las correctas se guardan '
                'y las que tengan errores te las devolvemos con el motivo para corregirlas.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _cargando ? null : _elegirArchivo,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nombreArchivo == null
                                    ? 'Haz clic para buscar el archivo (Excel .xlsx, .csv o .json)'
                                    : '$_nombreArchivo  ·  ${_rows?.length ?? 0} fila(s)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: _nombreArchivo == null ? Theme.of(context).hintColor : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _descargarPlantilla,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Descargar plantilla'),
                    ),
                  ),
                ],
              ),
              if (_errorArchivo != null) ...[
                const SizedBox(height: 8),
                Text(_errorArchivo!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Text(
                'Columnas (* obligatoria): ${_t.headers.map(_t.displayHeader).join('  ·  ')}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
              if (_cargando) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                const Text('Validando y cargando...', style: TextStyle(fontSize: 12)),
              ],
              if (report != null) ...[
                const SizedBox(height: 16),
                _ResultadoView(report: report),
                if (report.errores.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _descargarErrores,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Descargar filas con error'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(_huboCambios),
          child: Text(report == null ? 'Cancelar' : 'Cerrar'),
        ),
        if (report != null && report.errores.isNotEmpty)
          TextButton(
            onPressed: _cargando
                ? null
                : () => setState(() {
                      // Para volver a subir el archivo corregido.
                      _report = null;
                      _rows = null;
                      _nombreArchivo = null;
                    }),
            child: const Text('Subir otro archivo'),
          ),
        ElevatedButton(
          onPressed: puedeCargar ? _cargar : null,
          child: const Text('Cargar'),
        ),
      ],
    );
  }
}

class _ResultadoView extends StatelessWidget {
  final _BulkReport report;
  const _ResultadoView({required this.report});

  @override
  Widget build(BuildContext context) {
    final sinErrores = report.errores.isEmpty;
    final color = sinErrores ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sinErrores ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sinErrores
                      ? 'Listo: se cargaron las ${report.cargadas} fila(s) sin errores.'
                      : '${report.cargadas} de ${report.total} fila(s) cargadas. '
                          '${report.errores.length} con error.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (!sinErrores) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in report.errores)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Fila ${e.fila}: ${e.motivo}', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
