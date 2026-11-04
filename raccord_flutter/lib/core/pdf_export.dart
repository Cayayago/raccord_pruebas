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
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor(0.5, 0.5, 0.5, 0.3),
              ),
            ),
          ),
        ),
      );
    }
  }

  return pw.Stack(children: tiles);
}

/// Datos de UNA escena para el PDF de Desglose de Producción.
class DesgloseEscenaPdf {
  final String numero;
  final String encabezado;
  final String? espacio; // INT / EXT
  final String? momento; // Día / Noche...
  final int? pagina;
  final String? ciudad; // de la escena
  final String? locacion; // locación de rodaje (Plan de Rodaje)
  final String? diaDramatico; // de la escena
  final int? diaRodaje; // 1, 2, 3... según fechas de grabación
  final String? sinopsis;
  final List<String> reparto; // códigos de personaje (MED, SUA...)
  final List<List<String>> items; // [categoría, item, cantidad, notas]

  const DesgloseEscenaPdf({
    required this.numero,
    required this.encabezado,
    this.espacio,
    this.momento,
    this.ciudad,
    this.locacion,
    this.diaDramatico,
    this.diaRodaje,
    this.pagina,
    this.sinopsis,
    this.reparto = const [],
    this.items = const [],
  });
}

/// Encabezado del documento de Desglose de Producción (datos del
/// proyecto) — equivale al bloque superior del "Shooting Schedule" de
/// referencia: productora, título, director, formato y versión del guion.
class DesgloseProyectoPdf {
  final String nombre;
  final String? productora;
  final String? director;
  final String? formato;
  final String? genero;
  final String? guion; // "Nombre v8.1 (2026-04-26)"

  const DesgloseProyectoPdf({
    required this.nombre,
    this.productora,
    this.director,
    this.formato,
    this.genero,
    this.guion,
  });
}

/// PDF de Desglose de Producción del proyecto completo: bloque de datos
/// del proyecto y, a continuación, cada escena con su línea de escena
/// (N°, espacio, locación, momento, página), sinopsis, reparto y la
/// tabla de requerimientos por categoría.
Future<bool> exportDesglosePdf({
  required String fileName,
  required DesgloseProyectoPdf proyecto,
  required List<DesgloseEscenaPdf> escenas,
  required String marcaAguaTexto,
}) async {
  final doc = pw.Document();
  const pageFormat = PdfPageFormat.a4;
  const margin = pw.EdgeInsets.fromLTRB(32, 32, 32, 36);

  pw.Widget linea(String texto, {double size = 10, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(
          texto,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      );

  bool hay(String? s) => s != null && s.trim().isNotEmpty;

  final formatoGenero = [
    if (hay(proyecto.formato)) proyecto.formato!.trim(),
    if (hay(proyecto.genero)) proyecto.genero!.trim(),
  ].join(' - ');

  // Paleta Raccord (misma del PDF de Plan de Rodaje).
  const azul = PdfColor.fromInt(0xFF0B4F8A);
  const moradoOscuro = PdfColor.fromInt(0xFF4A3A8C);
  const noche = PdfColor.fromInt(0xFF0B0E14);
  const coral = PdfColor.fromInt(0xFFFF9B7A);
  const lila = PdfColor.fromInt(0xFFD6CBFF);
  const celeste = PdfColor.fromInt(0xFFBFE0FF);

  pw.Widget lineaColor(String texto, PdfColor color, {double size = 10, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(
          texto,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: size, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      );

  pw.Widget bloqueProyecto() => pw.Container(
        width: double.infinity,
        color: noche,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: pw.Column(
          children: [
            if (hay(proyecto.productora)) lineaColor('${proyecto.productora!.trim().toUpperCase()} PRESENTA', lila, size: 9),
            lineaColor(proyecto.nombre.toUpperCase(), coral, size: 18, bold: true),
            if (hay(proyecto.director)) lineaColor('Dirigida por ${proyecto.director!.trim()}', PdfColors.white, size: 10),
            if (formatoGenero.isNotEmpty) lineaColor(formatoGenero, celeste, size: 9),
            if (hay(proyecto.guion)) lineaColor('Guion: ${proyecto.guion!.trim()}', lila, size: 9),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              color: azul,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'DESGLOSE DE PRODUCCION - ${escenas.length} ${escenas.length == 1 ? 'escena' : 'escenas'}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  // Ciudad = dato de la escena; Locación de rodaje = dato del Plan de Rodaje.
  List<List<String>> datosEscena(DesgloseEscenaPdf e) => [
        if (hay(e.ciudad)) ['Ciudad', e.ciudad!.trim()],
        if (hay(e.locacion)) ['Locación de rodaje', e.locacion!.trim()],
        if (hay(e.diaDramatico)) ['Día dramático', e.diaDramatico!.trim()],
        if (e.diaRodaje != null) ['Día de rodaje', '${e.diaRodaje}'],
      ];

  pw.Widget bloqueEscena(DesgloseEscenaPdf e) {
    final lugar = e.encabezado.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          color: azul,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  if (hay(e.espacio)) ...[
                    pw.Text(e.espacio!.toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Expanded(
                    child: pw.Text(lugar,
                        maxLines: 2,
                        style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  if (hay(e.momento)) pw.Text(e.momento!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  if (e.pagina != null) ...[
                    pw.SizedBox(width: 10),
                    pw.Text('Pag. ${e.pagina}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  ],
                ],
              ),
              // Descripción de la escena, dentro del mismo recuadro del
              // encabezado (debajo de él).
              if (hay(e.sinopsis)) ...[
                pw.SizedBox(height: 3),
                pw.Text(e.sinopsis!.trim(), style: const pw.TextStyle(fontSize: 8.5, color: celeste)),
              ],
            ],
          ),
        ),
        if (datosEscena(e).isNotEmpty)
          pw.Container(
            width: double.infinity,
            color: _colorTira(e.espacio, e.momento),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  for (var i = 0; i < datosEscena(e).length; i++) ...[
                    if (i > 0) const pw.TextSpan(text: '     ', style: pw.TextStyle(fontSize: 8)),
                    pw.TextSpan(
                        text: '${datosEscena(e)[i][0]}: ',
                        style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: datosEscena(e)[i][1], style: const pw.TextStyle(fontSize: 8)),
                  ],
                ],
              ),
            ),
          ),
        if (e.reparto.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  const pw.TextSpan(text: 'Reparto: ', style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.TextSpan(
                    text: [for (var i = 0; i < e.reparto.length; i++) '${i + 1}. ${e.reparto[i]}'].join('   '),
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ],
              ),
            ),
          ),
        pw.SizedBox(height: 4),
        if (e.items.isEmpty)
          pw.Text('Sin items de desglose.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Categoria', 'Item', 'Cant.', 'Notas'],
            data: e.items,
            headerStyle: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: moradoOscuro),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F6FB)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(4),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(3),
            },
          ),
        pw.SizedBox(height: 14),
      ],
    );
  }

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
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Impreso: $marcaAguaTexto', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        ],
      ),
      build: (context) => [
        bloqueProyecto(),
        pw.SizedBox(height: 12),
        for (final e in escenas) bloqueEscena(e),
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

// ==========================================
// PLAN DE RODAJE (stripboard impreso)
// ==========================================

/// Una escena dentro de un día del plan de rodaje.
class PlanEscenaPdf {
  final String numero;
  final String? espacio; // INT / EXT / INT/EXT
  final String? momento; // Día / Noche...
  final int? diaDramatico;
  final String encabezado;
  final String? sinopsis;
  final List<String> reparto; // códigos de personaje (PERS-001...)
  final String? pagina;
  final String? tiempo; // tiempo estimado
  final String? hora; // hora de inicio
  final String? notas;
  final String? locacion;
  final String? ciudad;

  const PlanEscenaPdf({
    required this.numero,
    required this.encabezado,
    this.espacio,
    this.momento,
    this.diaDramatico,
    this.sinopsis,
    this.reparto = const [],
    this.pagina,
    this.tiempo,
    this.hora,
    this.notas,
    this.locacion,
    this.ciudad,
  });
}

/// Un día de rodaje con sus escenas ya ordenadas.
class PlanDiaPdf {
  final int? dia;
  final int? semana;
  final String? ubicacion; // ciudad/sitio del día
  final String? horaInicio;
  final String? horaFin;
  final DateTime? fecha;
  final List<PlanEscenaPdf> escenas;

  const PlanDiaPdf({this.dia, this.semana, this.ubicacion, this.horaInicio, this.horaFin, this.fecha, this.escenas = const []});
}

const _kMeses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const _kDias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

String _fechaLarga(DateTime f) => '${_kDias[f.weekday - 1]}, ${f.day} de ${_kMeses[f.month - 1]} de ${f.year}';

String _hhmm(String? h) {
  if (h == null || h.isEmpty) return '';
  final p = h.split(':');
  return p.length >= 2 ? '${p[0].padLeft(2, '0')}:${p[1]}' : h;
}

PdfColor _colorTira(String? espacio, String? momento) {
  final noche = (momento ?? '').toLowerCase().contains('noche');
  final ext = (espacio ?? '').toUpperCase() == 'EXT';
  // Tintes suaves de la paleta Raccord (coral, azul, morado).
  if (noche) return ext ? const PdfColor.fromInt(0xFFDDD3F6) : const PdfColor.fromInt(0xFFC7DBF0);
  return ext ? const PdfColor.fromInt(0xFFFBD9CC) : PdfColors.white;
}

/// PDF del Plan de Rodaje con el formato de stripboard impreso: leyenda
/// de Cast, bloques por semana y por día (call time, locación) y una
/// tira por escena (n.°, INT/EXT, encabezado, cast, sinopsis).
Future<bool> exportPlanRodajePdf({
  required String fileName,
  required String proyecto,
  String? guion,
  required List<String> castLegend, // "1. NOMBRE"
  required List<PlanDiaPdf> dias,
  required List<PlanEscenaPdf> sinAsignar,
  required String marcaAguaTexto,
}) async {
  final doc = pw.Document();
  const pageFormat = PdfPageFormat.a4;
  const margin = pw.EdgeInsets.fromLTRB(24, 24, 24, 30);
  // Paleta Raccord (ver theme/app_theme.dart): azul profundo, morado tech,
  // coral y el negro azulado del modo oscuro.
  const azul = PdfColor.fromInt(0xFF0B4F8A);
  const moradoOscuro = PdfColor.fromInt(0xFF4A3A8C);
  const noche = PdfColor.fromInt(0xFF0B0E14);
  const coral = PdfColor.fromInt(0xFFFF9B7A);
  const lila = PdfColor.fromInt(0xFFD6CBFF);
  const celeste = PdfColor.fromInt(0xFFBFE0FF);

  bool hay(String? s) => s != null && s.trim().isNotEmpty;

  pw.Widget banda(String texto, {PdfColor color = PdfColors.white, PdfColor fondo = const PdfColor.fromInt(0xFF0B4F8A), double size = 13, bool bold = false, double v = 5}) => pw.Container(
        width: double.infinity,
        color: fondo,
        padding: pw.EdgeInsets.symmetric(vertical: v, horizontal: 6),
        child: pw.Text(texto,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: size, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  pw.Widget tira(PlanEscenaPdf e) {
    final color = _colorTira(e.espacio, e.momento);
    final momento = hay(e.momento) ? e.momento! : '';
    final dd = e.diaDramatico != null ? ' ${e.diaDramatico}' : '';
    final extras = [
      if (hay(e.hora)) _hhmm(e.hora),
      if (hay(e.tiempo)) e.tiempo!,
      if (hay(e.notas)) e.notas!,
    ].join('  ');
    return pw.Container(
      decoration: pw.BoxDecoration(color: color, border: pw.Border.all(color: PdfColors.grey800, width: 0.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 34,
            padding: const pw.EdgeInsets.fromLTRB(3, 4, 2, 2),
            child: pw.Text(e.numero, style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 38,
                        child: pw.Text(hay(e.espacio) ? e.espacio!.toUpperCase() : '',
                            style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Expanded(
                        child: pw.Text(e.encabezado, maxLines: 2, style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(width: 6),
                      pw.SizedBox(
                        width: 150,
                        child: pw.Text('Cast: ${e.reparto.join(', ')}', maxLines: 3, style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(
                        width: 34,
                        child: pw.Text(hay(e.pagina) ? 'Pag. ${e.pagina}' : '',
                            textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 38,
                        child: pw.Text('$momento$dd', style: const pw.TextStyle(fontSize: 7)),
                      ),
                      pw.Expanded(
                        child: pw.Text(hay(e.sinopsis) ? e.sinopsis!.trim() : '',
                            style: const pw.TextStyle(fontSize: 7.5)),
                      ),
                      if (extras.isNotEmpty) ...[
                        pw.SizedBox(width: 6),
                        pw.SizedBox(
                          width: 110,
                          child: pw.Text(extras, textAlign: pw.TextAlign.right, maxLines: 2, style: const pw.TextStyle(fontSize: 7)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final contenido = <pw.Widget>[];

  // Encabezado del documento.
  contenido.add(pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey700, width: 0.6)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('CAST', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      if (castLegend.isEmpty)
        pw.Text('Sin personajes asignados a escenas.', style: const pw.TextStyle(fontSize: 8))
      else
        pw.Wrap(
          spacing: 14,
          runSpacing: 2,
          children: [for (final c in castLegend) pw.SizedBox(width: 200, child: pw.Text(c, style: const pw.TextStyle(fontSize: 8)))],
        ),
    ]),
  ));
  contenido.add(pw.SizedBox(height: 6));
  contenido.add(banda(proyecto.toUpperCase(), color: coral, fondo: noche, size: 18, bold: true, v: 12));
  contenido.add(banda('PLAN DE RODAJE', color: PdfColors.white, fondo: azul, size: 14, v: 8));
  if (hay(guion)) contenido.add(banda(guion!.toUpperCase(), color: lila, fondo: moradoOscuro, size: 12, v: 8));

  int? semanaActual;
  for (final d in dias) {
    if (d.semana != null && d.semana != semanaActual) {
      semanaActual = d.semana;
      contenido.add(pw.SizedBox(height: 4));
      contenido.add(banda('---SEMANA ${d.semana}---', color: lila, fondo: moradoOscuro, size: 13, bold: true, v: 10));
    }
    final fechaTxt = d.fecha != null ? '  |  ${_fechaLarga(d.fecha!)}' : '';
    contenido.add(banda(d.dia != null ? 'DIA ${d.dia}$fechaTxt' : 'DIA SIN NUMERO', color: PdfColors.white, fondo: azul, size: 14, bold: true, v: 6));
    final llamado = [
      if (hay(d.horaInicio)) _hhmm(d.horaInicio),
      if (hay(d.horaFin)) _hhmm(d.horaFin),
    ].join(' - ');

    // Orden dentro del día: ciudad -> locación (las escenas ya vienen
    // ordenadas así desde quien llama). Cada cambio de ciudad abre su
    // banda; el horario del día va debajo de la primera ciudad.
    String? ciudadActual;
    String? locacionActual;
    var primera = true;
    for (final e in d.escenas) {
      final ciudad = (e.ciudad ?? '').trim();
      if (primera || ciudad != ciudadActual) {
        ciudadActual = ciudad;
        locacionActual = null;
        if (ciudad.isNotEmpty) contenido.add(banda(ciudad.toUpperCase(), color: coral, fondo: noche, size: 12, bold: true, v: 4));
        if (primera && llamado.isNotEmpty) contenido.add(banda('LLAMADO $llamado', color: celeste, fondo: azul, size: 11, v: 4));
        primera = false;
      }
      if (hay(e.locacion) && e.locacion != locacionActual) {
        locacionActual = e.locacion;
        contenido.add(banda(e.locacion!.toUpperCase(), color: celeste, fondo: const PdfColor.fromInt(0xFF123A66), size: 10.5, v: 4));
      }
      contenido.add(tira(e));
    }
    if (d.escenas.isEmpty) {
      contenido.add(pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.5)),
        child: pw.Text('Sin escenas asignadas.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ));
    }
    final fin = d.fecha != null ? ' -- ${_fechaLarga(d.fecha!)} --' : '';
    contenido.add(pw.Container(
      width: double.infinity,
      color: moradoOscuro,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        '--- FIN DE DIA ${d.dia ?? ''}$fin ${d.escenas.length} ${d.escenas.length == 1 ? 'escena' : 'escenas'}',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    ));
  }

  if (sinAsignar.isNotEmpty) {
    contenido.add(pw.SizedBox(height: 6));
    contenido.add(banda('ESCENAS SIN ASIGNAR A UN DIA', color: coral, fondo: noche, size: 12, bold: true, v: 8));
    for (final e in sinAsignar) {
      contenido.add(tira(e));
    }
  }

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
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Impreso: $marcaAguaTexto', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        ],
      ),
      build: (context) => contenido,
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
          pw.Text(titulo, style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
          headerStyle: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
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
