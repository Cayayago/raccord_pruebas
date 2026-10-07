import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logos reales de marca, tomados de Marketing/Logos y organizados en
/// assets/images/logos/ — el mismo patrón que usa `raccord_frontend`
/// (carpeta src/assets/).
///
/// - isotipoColor: círculo de marca — login, registro, recuperar
///   contraseña, 2FA. Es a color (degradé), así que se ve bien en
///   modo oscuro y claro sin necesitar variante.
/// - logoCcNegativo / logoNegativo: variantes "negativas" (texto claro),
///   pensadas para fondo oscuro — logoCcNegativo en la barra superior de
///   TODAS las pantallas desde "Selección de Proyecto" en adelante
///   (AppScaffold y ProjectSelectionScreen), logoNegativo en la pantalla
///   obligatoria "Registra Proyecto".
/// - logoCcNegro / logoNegro: sus contrapartes en negro, para fondo
///   claro (modo claro) — sin esto el texto claro de las variantes
///   "negativo" queda invisible sobre fondo blanco. [AppWordmark] elige
///   automáticamente cuál mostrar según el tema activo.
class AppLogos {
  AppLogos._();
  static const isotipoColor = 'assets/images/logos/isotipo_color.png';
  static const logoCcNegativo = 'assets/images/logos/logo_cc_negativo.png';
  static const logoNegativo = 'assets/images/logos/logo_negativo.png';
  static const logoCcNegro = 'assets/images/logos/logo_cc_negro.png';
  static const logoNegro = 'assets/images/logos/logo_negro.png';
}

/// Isotipo circular de marca (mockups 1, 2, 5...). Si el archivo aún no
/// está copiado en assets/images/logos/, cae a un círculo con el
/// degradé de marca para no romper la pantalla.
class AppIsotipo extends StatelessWidget {
  final double size;
  const AppIsotipo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppLogos.isotipoColor,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientLogo,
        ),
      ),
    );
  }
}

/// Wordmark "Raccord" que aparece en la barra superior. Por defecto usa
/// el par Logo_CC_Negativo (modo oscuro) / Logo_CC_Negro (modo claro) —
/// la pantalla obligatoria "Registra Proyecto" pasa el par
/// `darkAsset: AppLogos.logoNegativo, lightAsset: AppLogos.logoNegro`
/// porque ahí va la otra variante (sin las "c" en color). En ambos
/// casos [AppWordmark] elige automáticamente cuál de los dos mostrar
/// según `Theme.of(context).brightness`, para que el logo nunca quede
/// invisible por poco contraste al cambiar de tema. Si el archivo no
/// está disponible todavía, cae al texto dibujado a mano.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  final Color baseColor;
  final String darkAsset;
  final String lightAsset;
  const AppWordmark({
    super.key,
    this.fontSize = 28,
    this.baseColor = Colors.white,
    this.darkAsset = AppLogos.logoCcNegativo,
    this.lightAsset = AppLogos.logoCcNegro,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? darkAsset : lightAsset,
      height: fontSize * 1.6,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackText(),
    );
  }

  Widget _fallbackText() {
    final style = TextStyle(
      fontFamily: 'Georgia',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: baseColor,
      letterSpacing: 0.5,
    );
    return RichText(
      text: TextSpan(style: style, children: [
        const TextSpan(text: 'Ra'),
        TextSpan(text: 'c', style: style.copyWith(color: AppColors.azulProfundo)),
        TextSpan(text: 'c', style: style.copyWith(color: AppColors.coral)),
        const TextSpan(text: 'ord'),
      ]),
    );
  }
}
