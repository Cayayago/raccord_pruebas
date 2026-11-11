import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../theme/app_theme.dart';

/// Un paso de cualquier recorrido guiado.
class TourStep {
  final String id;
  final GlobalKey key;
  final ContentAlign align;
  final String titulo;
  final String texto;
  const TourStep(this.id, this.key, this.align, this.titulo, this.texto);
}

/// Muestra un recorrido con los [pasos] cuyo widget está dibujado.
///
/// [mandatory] = true  -> sin "Saltar" y sin cerrar con el botón atrás.
/// [mandatory] = false -> recorrido voluntario, con "Saltar".
/// [onEnd] se llama al terminar o al saltar.
TutorialCoachMark showTour(
  BuildContext context,
  List<TourStep> pasos, {
  required bool mandatory,
  VoidCallback? onEnd,
}) {
  final visibles = pasos.where((p) => p.key.currentContext != null).toList();

  final targets = <TargetFocus>[
    for (var i = 0; i < visibles.length; i++)
      TargetFocus(
        identify: visibles[i].id,
        keyTarget: visibles[i].key,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: _posicion(context, visibles[i]),
            builder: (context, controller) => _TourContent(
              titulo: visibles[i].titulo,
              texto: visibles[i].texto,
              paso: i + 1,
              total: visibles.length,
            ),
          ),
        ],
      ),
  ];

  final tour = TutorialCoachMark(
    targets: targets,
    colorShadow: AppColors.azulProfundo,
    opacityShadow: 0.88,
    paddingFocus: 6,
    pulseEnable: false, // sin parpadeo: el elemento solo queda resaltado
    hideSkip: mandatory,
    disableBackButton: mandatory,
    textSkip: 'SALTAR',
    onFinish: () => onEnd?.call(),
    onSkip: () {
      onEnd?.call();
      return true;
    },
  );
  tour.show(context: context);
  return tour;
}

/// Ancho del bloque de texto: máximo 360 y nunca más que la pantalla.
double _anchoTexto(BuildContext context) =>
    (MediaQuery.of(context).size.width - 24).clamp(200.0, 360.0).toDouble();

/// Posición explícita del texto junto al elemento resaltado. La automática
/// de la librería falla con elementos muy altos (p. ej. la lista lateral):
/// el texto quedaba fuera de pantalla y no se veía.
CustomTargetContentPosition _posicion(BuildContext context, TourStep p) {
  const alto = 240.0; // alto aproximado del texto (con varias líneas)
  const sep = 20.0;
  final pantalla = MediaQuery.of(context).size;
  final w = _anchoTexto(context);
  final box = p.key.currentContext!.findRenderObject() as RenderBox;
  final pos = box.localToGlobal(Offset.zero);
  final tam = box.size;

  double izq(double x) => x.clamp(12.0, (pantalla.width - w - 12).clamp(12.0, 99999.0)).toDouble();
  double arriba(double y) => y.clamp(70.0, (pantalla.height - alto - 12).clamp(70.0, 99999.0)).toDouble();

  final cabeDerecha = pos.dx + tam.width + sep + w <= pantalla.width;
  final cabeIzquierda = pos.dx - sep - w >= 0;
  final cabeAbajo = pos.dy + tam.height + sep + alto <= pantalla.height;
  final cabeArriba = pos.dy - sep - alto >= 60;

  ContentAlign a = p.align;
  // Si el lado pedido no cabe, se usa el que sí quepa.
  bool cabe(ContentAlign x) => switch (x) {
        ContentAlign.right => cabeDerecha,
        ContentAlign.left => cabeIzquierda,
        ContentAlign.bottom => cabeAbajo,
        ContentAlign.top => cabeArriba,
        _ => true,
      };
  if (!cabe(a)) {
    a = [ContentAlign.right, ContentAlign.bottom, ContentAlign.left, ContentAlign.top]
        .firstWhere(cabe, orElse: () => ContentAlign.bottom);
  }

  switch (a) {
    case ContentAlign.right:
      return CustomTargetContentPosition(left: pos.dx + tam.width + sep, top: arriba(pos.dy + 16));
    case ContentAlign.left:
      return CustomTargetContentPosition(left: pos.dx - sep - w, top: arriba(pos.dy + 16));
    case ContentAlign.top:
      return CustomTargetContentPosition(left: izq(pos.dx), top: arriba(pos.dy - sep - alto));
    default:
      // Abajo; si no cabe en ningún lado, sobre el elemento.
      return CustomTargetContentPosition(left: izq(pos.dx), top: arriba(pos.dy + tam.height + sep));
  }
}

class _TourContent extends StatelessWidget {
  final String titulo;
  final String texto;
  final int paso;
  final int total;
  const _TourContent({required this.titulo, required this.texto, required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    // Align suelta las restricciones del padre (que llegaban "ajustadas" al
    // ancho de pantalla y estiraban el texto fuera de la vista) y SizedBox
    // fija el ancho para que el texto salte de línea.
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
      width: _anchoTexto(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paso $paso de $total', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          const Text('Toca la pantalla para continuar', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
      ),
    );
  }
}
