import 'package:flutter/material.dart';

/// Key global del Navigator raíz. Se usa desde widgets que viven
/// "fuera" del árbol de rutas normal (como InactivityWatcher, que
/// envuelve el Navigator entero vía MaterialApp.builder) y necesitan
/// mostrar diálogos o navegar sin tener un BuildContext de pantalla a
/// mano.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
