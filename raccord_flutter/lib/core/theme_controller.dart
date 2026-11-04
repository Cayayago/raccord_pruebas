import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Controla si la app se ve en modo oscuro o claro.
///
/// El modo elegido se guarda en el navegador/dispositivo para que al
/// actualizar la página (F5) se mantenga. Al cerrar sesión (manual o por
/// inactividad) se vuelve a oscuro, que es el modo por defecto del login
/// (ver [resetToDark]).
///
/// También mantiene sincronizado `AppColors.isDark`, que es lo que usan
/// las pantallas que pintan sus superficies con `AppColors.bg/surface/
/// surfaceVariant/border` directo (en vez de `Theme.of(context)`).
class ThemeController extends ChangeNotifier {
  static const _prefKey = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeController({ThemeMode initial = ThemeMode.dark}) : _mode = initial {
    AppColors.isDark = isDark;
  }

  /// Lee el modo guardado ANTES de pintar la primera pantalla (se llama
  /// desde main) para que no haya un parpadeo oscuro al recargar.
  static Future<ThemeMode> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKey) == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, isDark ? 'dark' : 'light');
    } catch (_) {}
  }

  void toggle() {
    final nuevoModo = isDark ? ThemeMode.light : ThemeMode.dark;
    _mode = nuevoModo;
    AppColors.isDark = nuevoModo == ThemeMode.dark;
    notifyListeners();
    _save();
  }

  // Al cerrar sesión, el login debe quedar siempre en oscuro (modo por
  // defecto), sin importar qué modo tenía elegido la persona.
  void resetToDark() {
    if (_mode == ThemeMode.dark) return;
    _mode = ThemeMode.dark;
    AppColors.isDark = true;
    notifyListeners();
    _save();
  }
}
