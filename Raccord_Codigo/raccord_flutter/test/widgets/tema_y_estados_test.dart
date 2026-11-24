// Capa Front — tema claro/oscuro y vistas de estado compartidas
// (lib/theme/app_theme.dart, lib/core/theme_controller.dart,
// lib/widgets/state_views.dart, lib/widgets/app_logo.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/theme_controller.dart';
import 'package:raccord/theme/app_theme.dart';
import 'package:raccord/widgets/app_logo.dart';
import 'package:raccord/widgets/state_views.dart';

Widget _app(Widget hijo, {ThemeData? tema}) => MaterialApp(theme: tema, home: Scaffold(body: hijo));

void main() {
  tearDown(() => AppColors.isDark = true);

  group('AppTheme', () {
    test('el tema oscuro y el claro tienen el brillo correcto', () {
      final oscuro = AppTheme.dark;
      final claro = AppTheme.light;

      expect(oscuro.brightness, Brightness.dark);
      expect(claro.brightness, Brightness.light);
      expect(oscuro.useMaterial3 && claro.useMaterial3, isTrue);
    });

    test('las superficies cambian con el modo y el texto contrasta', () {
      AppColors.isDark = true;
      final oscuras = [AppColors.bg, AppColors.surface, AppColors.surfaceVariant, AppColors.border];
      expect(AppColors.textPrimary, AppColors.blanco);

      AppColors.isDark = false;
      final claras = [AppColors.bg, AppColors.surface, AppColors.surfaceVariant, AppColors.border];
      expect(AppColors.textPrimary, AppColors.negro);

      for (var i = 0; i < oscuras.length; i++) {
        expect(oscuras[i], isNot(claras[i]));
      }
    });
  });

  group('ThemeController', () {
    test('arranca en oscuro, toggle alterna y avisa a quien escucha', () {
      final controlador = ThemeController();
      var avisos = 0;
      controlador.addListener(() => avisos++);

      expect([controlador.isDark, controlador.mode, AppColors.isDark], [true, ThemeMode.dark, true]);
      controlador.toggle();
      expect([controlador.isDark, controlador.mode, AppColors.isDark], [false, ThemeMode.light, false]);
      controlador.toggle();
      expect(controlador.isDark, isTrue);
      expect(avisos, 2);
    });

    test('resetToDark vuelve a oscuro y no avisa si ya estaba oscuro', () {
      final controlador = ThemeController();
      var avisos = 0;
      controlador.addListener(() => avisos++);

      controlador.resetToDark();
      expect(avisos, 0);

      controlador.toggle();
      controlador.resetToDark();
      expect([controlador.isDark, AppColors.isDark, avisos], [true, true, 2]);
    });
  });

  group('Vistas de estado', () {
    testWidgets('LoadingView muestra el indicador de carga', (tester) async {
      await tester.pumpWidget(_app(const LoadingView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorView muestra el mensaje y Reintentar llama a onRetry', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(_app(ErrorView(message: 'Sin conexión', onRetry: () => reintentos++)));

      expect(find.text('Sin conexión'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('ErrorView sin onRetry no ofrece reintentar', (tester) async {
      await tester.pumpWidget(_app(const ErrorView(message: 'Error')));

      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('EmptyView muestra el mensaje y la acción si la hay', (tester) async {
      await tester.pumpWidget(_app(EmptyView(
        message: 'Aún no hay escenas',
        icon: Icons.movie_outlined,
        action: TextButton(onPressed: () {}, child: const Text('Crear escena')),
      )));

      expect(find.text('Aún no hay escenas'), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
      expect(find.text('Crear escena'), findsOneWidget);
    });

    testWidgets('ComingSoonView muestra título y detalle', (tester) async {
      await tester.pumpWidget(_app(const ComingSoonView(title: 'Inventario', detail: 'Próximamente')));

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Próximamente'), findsOneWidget);
    });

    testWidgets('StatusPill muestra la etiqueta', (tester) async {
      await tester.pumpWidget(_app(const StatusPill(label: 'Finalizada', color: AppColors.success)));

      expect(find.text('Finalizada'), findsOneWidget);
    });
  });

  group('confirmDelete', () {
    Future<bool?> abrir(WidgetTester tester, String boton) async {
      bool? resultado;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () async => resultado = await confirmDelete(context, message: 'Se borrará la escena 12'),
          child: const Text('Borrar'),
        ),
      )));
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar este elemento?'), findsOneWidget);
      expect(find.text('Se borrará la escena 12'), findsOneWidget);
      await tester.tap(find.text(boton));
      await tester.pumpAndSettle();
      return resultado;
    }

    testWidgets('Eliminar confirma (true)', (tester) async {
      expect(await abrir(tester, 'Eliminar'), isTrue);
    });

    testWidgets('Cancelar no confirma (false, nunca null)', (tester) async {
      expect(await abrir(tester, 'Cancelar'), isFalse);
    });
  });

  group('Logo', () {
    testWidgets('el isotipo y el wordmark se dibujan en tema oscuro y claro', (tester) async {
      for (final tema in [AppTheme.dark, AppTheme.light]) {
        await tester.pumpWidget(_app(const Column(children: [AppIsotipo(size: 40), AppWordmark()]), tema: tema));

        expect(find.byType(AppIsotipo), findsOneWidget);
        expect(find.byType(AppWordmark), findsOneWidget);
      }
    });
  });
}
