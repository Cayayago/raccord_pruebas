import 'package:flutter/material.dart';

import '../core/bulk_import.dart';
import '../core/responsive.dart';

/// Botón "Carga masiva" reutilizable (escenas, personajes, actores,
/// roles). Se encarga de la parte genérica: elegir el archivo
/// (.csv/.json — Excel se exporta a CSV antes de subirlo, ver
/// core/bulk_import.dart), delegar la creación fila por fila a
/// [onRows] (cada pantalla sabe cómo mapear sus propias columnas y a
/// qué endpoint llamar), y mostrar un resumen de éxitos/errores al
/// final. [onDone] se llama al cerrar el resumen, para que la pantalla
/// recargue su lista.
class BulkUploadButton extends StatefulWidget {
  final Future<List<BulkRowResult>> Function(List<Map<String, String>> rows) onRows;
  final VoidCallback? onDone;

  const BulkUploadButton({super.key, required this.onRows, this.onDone});

  @override
  State<BulkUploadButton> createState() => _BulkUploadButtonState();
}

class _BulkUploadButtonState extends State<BulkUploadButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final icon = _loading
        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.upload_file_outlined, size: 18);

    // En móvil/tablet angosto, el texto "Carga masiva" junto a los demás
    // botones de la barra superior (Agregar Persona, home, notificaciones,
    // menú, avatar) era lo que desbordaba el AppBar. Se colapsa a un
    // ícono solo (con tooltip) en pantallas angostas, igual que el resto
    // de acciones responsive del AppBar.
    if (isMobileScreen(context)) {
      return IconButton(
        onPressed: _loading ? null : _run,
        icon: icon,
        tooltip: 'Carga masiva',
        style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline)),
      );
    }

    return OutlinedButton.icon(
      onPressed: _loading ? null : _run,
      icon: icon,
      label: const Text('Carga masiva'),
    );
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    List<BulkRowResult>? results;

    try {
      final rows = await pickAndParseBulkFile();
      if (rows == null) return; // se canceló el selector de archivos

      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo no tiene filas de datos (solo encabezado o está vacío)')),
          );
        }
        return;
      }

      results = await widget.onRows(rows);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo procesar el archivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (results != null && mounted) {
      await _showSummary(results);
      widget.onDone?.call();
    }
  }

  Future<void> _showSummary(List<BulkRowResult> results) {
    final exitosos = results.where((r) => r.ok).length;
    final fallidos = results.where((r) => !r.ok).toList();

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resultado de la carga masiva'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$exitosos de ${results.length} fila(s) se cargaron correctamente.'),
              if (fallidos.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Filas con error:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: fallidos
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('Fila ${r.fila}: ${r.detalle}', style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
