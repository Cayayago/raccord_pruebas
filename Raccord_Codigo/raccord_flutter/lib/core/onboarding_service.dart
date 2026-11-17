import 'package:shared_preferences/shared_preferences.dart';

/// Resultado de evaluar las reglas del recorrido guiado.
class OnboardingState {
  /// Primer ingreso (recorrido sin terminar): se lanza solo y sin "Saltar".
  final bool mandatory;

  /// Primera semana con el recorrido ya completado: se muestra el botón
  /// "Ver Recorrido" en la barra superior (aquí sí se puede "Saltar").
  final bool showButton;

  const OnboardingState({required this.mandatory, required this.showButton});

  static const hidden = OnboardingState(mandatory: false, showButton: false);
}

/// Reglas de negocio del onboarding, guardadas localmente con
/// `shared_preferences`:
///
/// 1. Recorrido sin completar            -> obligatorio (auto, sin Saltar).
/// 2. Completado y < 7 días del primer
///    ingreso (días 1 al 7)              -> botón "Ver Recorrido" opcional.
/// 3. Completado y >= 7 días             -> el botón desaparece.
///
/// `registration_date` (ISO8601) es único por usuario; el estado
/// `has_completed_tour` es por usuario Y por recorrido (`tourId`:
/// 'projects', 'dashboard', ...), así cada pantalla tiene su propia guía
/// pero comparten la misma fecha de primer ingreso.
class OnboardingService {
  static const String _kRegistration = 'registration_date';
  static const String _kCompleted = 'has_completed_tour';
  static const int diasDeAyuda = 7;

  final String userId;
  final String tourId;

  const OnboardingService({required this.userId, required this.tourId});

  String get _regKey => '${_kRegistration}_$userId';
  String get _doneKey => '${_kCompleted}_${tourId}_$userId';

  Future<OnboardingState> evaluate() async {
    final prefs = await SharedPreferences.getInstance();

    // Primer ingreso: se guarda la fecha una sola vez.
    var registro = DateTime.tryParse(prefs.getString(_regKey) ?? '');
    if (registro == null) {
      registro = DateTime.now();
      await prefs.setString(_regKey, registro.toIso8601String());
    }

    final completado = prefs.getBool(_doneKey) ?? false;
    if (!completado) {
      return const OnboardingState(mandatory: true, showButton: false);
    }

    final dias = DateTime.now().difference(registro).inDays;
    return OnboardingState(mandatory: false, showButton: dias < diasDeAyuda);
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }
}
