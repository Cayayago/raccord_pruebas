import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Envuelve [child] en un `RefreshIndicator` (deslizar hacia abajo para
/// recargar) SOLO en la app nativa (Android/iOS) — pedido explícito del
/// usuario (2026-09-21): "esto debe estar aplicado a toda la parte
/// móvil o tablet". En Web/PC no se agrega: no es un gesto que la gente
/// espere con mouse/trackpad, y ya existen botones "Reintentar" para
/// los estados de error.
///
/// Igual que `canUseSplitView` en core/responsive.dart, `kIsWeb` por sí
/// solo ya identifica "es PC" de forma confiable en este proyecto (la
/// decisión de producto ya tomada es PC = Web, Móvil/Tablet = app
/// nativa — nunca hay un navegador corriendo en el celular/tablet).
///
/// IMPORTANTE: [child] debe contener, en su estado actual, un
/// Scrollable descendiente (ListView/GridView/SingleChildScrollView)
/// con `physics: const AlwaysScrollableScrollPhysics()` — sin eso, el
/// gesto de "jalar para refrescar" no se activa cuando el contenido es
/// más corto que la pantalla (caso común en listas vacías o con pocos
/// resultados).
class MobileRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const MobileRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}
