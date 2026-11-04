import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Visor Polaroid genérico para CUALQUIER foto que no sea de continuidad
/// (fotos de actor "personaje"/"normal", foto de perfil, imágenes de
/// notificaciones...). Mismo marco que `showPhotoViewerDialog`: papel
/// blanco, imagen cuadrada arriba y franja inferior con el título.
/// Permite acercar con pellizco/rueda (InteractiveViewer).
///
/// Pasa [bytes] (Future) o [data] ya descargado.
Future<void> showPolaroidDialog(
  BuildContext context, {
  Future<List<int>>? bytes,
  List<int>? data,
  String? titulo,
  String? subtitulo,
}) {
  assert(bytes != null || data != null);
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10))],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: data != null
                              ? _img(data)
                              : FutureBuilder<List<int>>(
                                  future: bytes,
                                  builder: (context, snap) {
                                    if (snap.hasError) {
                                      return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40));
                                    }
                                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                                    return _img(snap.data!);
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titulo != null && titulo.isNotEmpty)
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    if (subtitulo != null && subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _img(List<int> data) => InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(child: Image.memory(Uint8List.fromList(data), fit: BoxFit.contain)),
    );
