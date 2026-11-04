import 'package:flutter/material.dart';

/// Paleta de marca Raccord, tomada de LandingScreen.css (frontend React
/// existente) para mantener consistencia visual entre plataformas.
class AppColors {
  AppColors._();

  static const azulProfundo = Color(0xFF0B4F8A);
  static const moradoTech = Color(0xFF7B5FCF);
  static const coral = Color(0xFFE67E5C);
  static const negro = Color(0xFF0A0A0A);
  static const grisOscuro = Color(0xFF3D3D3D);
  static const grisMedio = Color(0xFF6B6B6B);
  static const grisClaro = Color(0xFFE8E8E8);
  static const blanco = Color(0xFFFFFFFF);

  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE74C3C);

  // Superficies (mockups usan fondos oscuros con tarjetas ligeramente
  // más claras que el fondo).
  //
  // IMPORTANTE: la mayoría de pantallas pintan sus superficies con
  // `Container(color: AppColors.surface/bg/...)` directo en vez de leer
  // `Theme.of(context).colorScheme`. Para que el modo claro se vea bien
  // sin tener que tocar cada pantalla una por una, `bg`/`surface`/
  // `surfaceVariant`/`border` dejaron de ser `const` y ahora son
  // getters que devuelven el color oscuro o claro según [isDark].
  // [isDark] se mantiene sincronizado por `ThemeController` cada vez
  // que el usuario cambia de modo (ver core/theme_controller.dart).
  static bool isDark = true;

  // Antes era negro puro (0xFF0A0A0A, R=G=B). Se cambió a un azul
  // marino casi negro (mismo matiz que azulProfundo, muy oscurecido)
  // porque el negro puro se veía "plano"/sin vida en pantallas grandes.
  // El resto de la escala (surface/surfaceVariant/border) se corrió al
  // mismo matiz para que todo el modo oscuro se sienta cohesivo.
  static const _bgDark = Color(0xFF0B0E14);
  static const _surfaceDark = Color(0xFF12151D);
  static const _surfaceVariantDark = Color(0xFF1A1E29);
  static const _borderDark = Color(0xFF272C3A);

  // Tono "hueso"/crema (no blanco puro) pedido explícitamente por el
  // usuario, tomado con cuentagotas de las capturas de FilmScript
  // adjuntadas (fondo ~#F5F0E8, tarjetas ~#FEFCF6).
  static const _bgLight = Color(0xFFF5F0E8);
  static const _surfaceLight = Color(0xFFFEFCF6);
  static const _surfaceVariantLight = Color(0xFFEFEADD);
  static const _borderLight = Color(0xFFE3DDCE);

  static Color get bg => isDark ? _bgDark : _bgLight;
  static Color get surface => isDark ? _surfaceDark : _surfaceLight;
  static Color get surfaceVariant => isDark ? _surfaceVariantDark : _surfaceVariantLight;
  static Color get border => isDark ? _borderDark : _borderLight;

  /// Color de texto/ícono "normal" sobre [surface]/[bg]: blanco en modo
  /// oscuro, negro en modo claro. Útil para textos que hoy están fijos
  /// en `AppColors.blanco` fuera de los botones/badges de color.
  static Color get textPrimary => isDark ? blanco : negro;

  static const gradientLogo = LinearGradient(
    colors: [azulProfundo, moradoTech, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    const bgDark = Color(0xFF0B0E14);
    const surfaceDark = Color(0xFF12151D);
    const surfaceVariantDark = Color(0xFF1A1E29);
    const borderDark = Color(0xFF272C3A);

    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: AppColors.azulProfundo,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.azulProfundo,
        secondary: AppColors.moradoTech,
        tertiary: AppColors.coral,
        surface: surfaceDark,
        error: AppColors.error,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Montserrat',
        bodyColor: AppColors.blanco,
        displayColor: AppColors.blanco,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.blanco,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgDark,
        hintStyle: const TextStyle(color: AppColors.grisMedio),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.azulProfundo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulProfundo,
          foregroundColor: AppColors.blanco,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blanco,
          side: const BorderSide(color: borderDark),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.azulProfundo),
      ),
      dividerTheme: const DividerThemeData(color: borderDark),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariantDark,
        contentTextStyle: const TextStyle(color: AppColors.blanco),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // TEMA CLARO
  // ==========================================
  // Las superficies con color "fijo" (tarjetas de escenas/guiones,
  // fondos de pantalla, etc.) que usan `AppColors.bg/surface/
  // surfaceVariant/border` directo ya no quedan oscuras en este modo:
  // esos 4 colores son getters dinámicos (ver AppColors.isDark) que
  // ThemeController mantiene sincronizados con el modo activo.
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    const bgLight = Color(0xFFF5F0E8);
    const surfaceLight = Color(0xFFFEFCF6);
    const borderLight = Color(0xFFE3DDCE);

    return base.copyWith(
      scaffoldBackgroundColor: bgLight,
      primaryColor: AppColors.azulProfundo,
      colorScheme: const ColorScheme.light(
        primary: AppColors.azulProfundo,
        secondary: AppColors.moradoTech,
        tertiary: AppColors.coral,
        surface: surfaceLight,
        error: AppColors.error,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Montserrat',
        bodyColor: AppColors.negro,
        displayColor: AppColors.negro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.negro,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        hintStyle: const TextStyle(color: AppColors.grisMedio),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.azulProfundo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulProfundo,
          foregroundColor: AppColors.blanco,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.negro,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.azulProfundo),
      ),
      dividerTheme: const DividerThemeData(color: borderLight),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grisOscuro,
        contentTextStyle: const TextStyle(color: AppColors.blanco),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
