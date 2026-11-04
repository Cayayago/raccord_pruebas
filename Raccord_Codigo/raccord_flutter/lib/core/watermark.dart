import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, Color, FontWeight, Offset;

import 'session.dart';

/// Texto que se estampa en TODO lo que el usuario descarga de Raccord
/// (guion en PDF, Plan de Rodaje, Desglose, fotos de continuidad):
/// "Nombre Apellido - fecha hora". Mismo criterio en los 4 lugares para
/// que la marca siempre identifique quién descargó el archivo.
/// Respaldo en el correo si por algo el nombre/apellido vinieran vacíos
/// (cuenta muy vieja sin esos campos cargados, por ejemplo).
String watermarkTextFor(AuthSession session) {
  final user = session.user;
  final nombreCompleto = user == null ? '' : '${user.nombre} ${user.apellido}'.trim();
  final quien = nombreCompleto.isNotEmpty ? nombreCompleto : (user?.mail ?? 'usuario desconocido');

  final ahora = DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  final fecha = '${ahora.year}-${dos(ahora.month)}-${dos(ahora.day)} ${dos(ahora.hour)}:${dos(ahora.minute)}';

  return '$quien - $fecha';
}

/// Dibuja [texto] en mosaico diagonal y semitransparente sobre la imagen
/// [bytes] (mismo criterio visual que la marca de agua de los PDFs) y
/// devuelve un PNG con el resultado. Se usa para las fotos de
/// continuidad que se descargan desde la Galería.
///
/// NOTA: la salida siempre es PNG, sin importar el formato de entrada
/// (jpg, png, etc.) — el motor de dibujo de Flutter (dart:ui) solo sabe
/// re-codificar a PNG, no a JPEG. Es un cambio de extensión, no de
/// calidad visible para este uso (fotos de referencia/continuidad).
Future<Uint8List> watermarkImageBytes(Uint8List bytes, String texto) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final imagen = frame.image;

  final ancho = imagen.width.toDouble();
  final alto = imagen.height.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, ancho, alto));

  // Foto original, sin recortar ni deformar.
  canvas.drawImage(imagen, ui.Offset.zero, ui.Paint());

  // Tamaño de fuente proporcional a la imagen: en una foto de 4000px
  // una marca de 10px sería invisible; en una miniatura de 200px una de
  // 40px taparía todo.
  final fontSize = (ancho * 0.028).clamp(14.0, 42.0);
  final painter = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: const Color(0x47FFFFFF), // blanco, ~28% opacidad
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final stepX = painter.width + fontSize * 4;
  final stepY = painter.height + fontSize * 6;

  for (double y = -stepY; y < alto + stepY; y += stepY) {
    for (double x = -stepX; x < ancho + stepX; x += stepX) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.5); // mismo giro diagonal que en los PDFs
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  final picture = recorder.endRecording();
  final resultado = await picture.toImage(imagen.width, imagen.height);
  final byteData = await resultado.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
