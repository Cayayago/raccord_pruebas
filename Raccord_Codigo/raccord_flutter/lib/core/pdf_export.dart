import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Construye la marca de agua diagonal y repetida en mosaico sobre toda
/// la página — mismo criterio visual que la marca del guion en PDF (ver
/// app/utils/watermark.py en el backend): texto del usuario + fecha,
/// gris/blanco semitransparente, rotado. Se usa como fondo
/// (buildBackground) de cada página del reporte, así que se repite
/// automáticamente en todas las páginas sin importar cuántas sean.
pw.Widget _buildWatermarkOverlay(String texto, PdfPageFormat pageFormat) {
  const stepX = 220.0;
  const stepY = 110.0;

  final tiles = <pw.Widget>[];
  for (double y = -60; y < pageFormat.height + stepY; y += stepY) {
    for (double x = -140; x < pageFormat.width + stepX; x += stepX) {
      tiles.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.Transform.rotate(
            angle: -0.5, // mismo giro diagonal que en el guion y las fotos
            child: pw.Text(
              texto,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor(0.5, 0.5, 0.5, 0.3),
              ),
            ),
          ),
        ),
      );
    }
  }

  return pw.Stack(children: tiles);
}

/// Genera un reporte en PDF (título + tabla) y dispara la descarga con
/// FileSaver — usado por TODOS los botones "Descargar" de la app
/// (Desglose, Plan de Rodaje). Decisión explícita del usuario: ninguna
/// descarga debe salir en CSV/Excel/otro formato, todas en PDF.
///
/// [headers] son los títulos de columna y [rows] cada fila ya formateada
/// a texto (el llamador decide qué mostrar en cada celda). Se usa
/// orientación horizontal (landscape) porque estos reportes tienden a
/// tener muchas columnas angostas.
///
/// [marcaAguaTexto] identifica a quién descargó el archivo (mismo
/// criterio que el guion en PDF: nombre y apellido + fecha/hora) — se
/// estampa en mosaico sobre cada página, a pedido explícito del usuario
/// para trazabilidad de todo lo que se descarga desde Raccord.
///
/// Devuelve `true` si el archivo se guardó de verdad, `false` si la
/// persona cerró/canceló el selector "Guardar como" sin elegir carpeta.
/// Antes se usaba `FileSaver.saveFile()`, que en Android guarda directo
/// en una carpeta PRIVADA de la app (`Android/data/<paquete>/files/...`)
/// sin preguntar ni avisar — no dispara la notificación de descarga de
/// Android ni aparece en "Archivos"/Descargas, así que la persona nunca
/// encontraba el PDF aunque la app dijera "Descarga iniciada". `saveAs()`
/// abre el selector nativo de Android para que la persona elija la
/// carpeta (típicamente Descargas), igual que cualquier otra descarga.
Future<bool> exportTablePdf({
  required String fileName,
  required String titulo,
  String? subtitulo,
  required List<String> headers,
  required List<List<String>> rows,
  List<int>? anchoColumnasFlex,
  required String marcaAguaTexto,
}) async {
  final doc = pw.Document();
  final pageFormat = PdfPageFormat.a4.landscape;
  const margin = pw.EdgeInsets.all(24);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: pageFormat,
        margin: margin,
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: _buildWatermarkOverlay(marcaAguaTexto, pageFormat),
        ),
      ),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (subtitulo != null && subtitulo.isNotEmpty)
            pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          cellHeight: 20,
          columnWidths: anchoColumnasFlex == null
              ? null
              : {
                  for (var i = 0; i < anchoColumnasFlex.length; i++) i: pw.FlexColumnWidth(anchoColumnasFlex[i].toDouble()),
                },
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  final savedPath = await FileSaver.instance.saveAs(
    name: fileName,
    bytes: Uint8List.fromList(bytes),
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
  return savedPath != null;
}
