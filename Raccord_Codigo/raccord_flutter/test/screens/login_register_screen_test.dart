// Semana 3 — Front: LoginRegisterScreen (Deiver).
//
// Pantalla de Ingresar / Registrar (lib/screens/auth/login_register_screen.dart).
// Se prueba como la usa una persona: busca los elementos por su texto o
// etiqueta visible, escribe, toca y mira qué aparece. El backend es un
// MockClient (ver test/helpers/pump_with_providers.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:raccord/screens/auth/login_register_screen.dart';

import '../helpers/pump_with_providers.dart';

const usuarioJson = {
  'id_user': 'u1',
  'nombre': 'ana',
  'apellido': 'ruiz',
  'mail': 'ana@raccord.co',
  'id_rol': 1001,
};

/// Botón "Ingresar" del formulario (hay otro "Ingresar": la pestaña).
Finder get botonIngresar => find.widgetWithText(ElevatedButton, 'Ingresar');
Finder get botonRegistrar => find.widgetWithText(ElevatedButton, 'Registrar');

/// Equivale a toBeDisabled(): un botón de Material sin onPressed está deshabilitado.
bool deshabilitado(WidgetTester tester, Finder boton) => tester.widget<ElevatedButton>(boton).onPressed == null;

/// Deja que el SnackBar termine de mostrarse y se cierre (evita timers pendientes).
Future<void> cerrarSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('Ingresar', () {
    testWidgets('con los campos vacíos muestra la validación y no llama a la API', (tester) async {
      // Arrange
      final peticiones = <http.Request>[];
      await pumpWithProviders(tester, const LoginRegisterScreen(), peticiones: peticiones);
      // El hint y el error usan el mismo texto: antes de enviar solo está el hint.
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);

      // Act
      await tester.tap(botonIngresar);
      await tester.pump();

      // Assert: ahora aparece también el mensaje de error de cada campo
      expect(find.text('Ingresa tu correo'), findsNWidgets(2));
      expect(find.text('Ingresa tu contraseña'), findsNWidgets(2));
      expect(peticiones, isEmpty);
    });

    testWidgets('con credenciales incorrectas muestra el mensaje del backend y no entra', (tester) async {
      // Arrange
      const mensaje = 'Verifica tu correo y tu contraseña: alguno de los dos no es correcto.';
      final session = await pumpWithProviders(
        tester,
        const LoginRegisterScreen(),
        api: (_) async => respuesta(null, success: false, message: mensaje, error: 'INVALID_CREDENTIALS'),
      );

      // Act
      await tester.enterText(campo('E-mail'), 'ana@raccord.co');
      await tester.enterText(campo('Contraseña'), 'ClaveMala1!');
      await tester.tap(botonIngresar);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Pantalla: /proyectos'), findsNothing); // equivale a queryBy: no navegó
      expect(session.isAuthenticated, isFalse);
      await cerrarSnackBar(tester);
    });

    testWidgets('con credenciales correctas guarda la sesión y lleva a Proyectos', (tester) async {
      // Arrange
      final peticiones = <http.Request>[];
      final session = await pumpWithProviders(
        tester,
        const LoginRegisterScreen(),
        peticiones: peticiones,
        api: (req) async => switch (req.url.path) {
          '/users/2fa/check' => respuesta({'requires_2fa': false}),
          '/users/login' => respuesta({'access_token': 'jwt-123', 'usuario': usuarioJson}),
          _ => respuesta(null, success: false, status: 404),
        },
      );

      // Act
      await tester.enterText(campo('E-mail'), 'ana@raccord.co');
      await tester.enterText(campo('Contraseña'), 'Clave\$egura1');
      await tester.tap(botonIngresar);
      await tester.pumpAndSettle();

      // Assert: equivale a findBy, se espera a que termine la navegación
      expect(find.text('Pantalla: /proyectos'), findsOneWidget);
      expect(session.isAuthenticated, isTrue);
      expect(peticiones.map((r) => r.url.path), ['/users/2fa/check', '/users/login']);
    });

    testWidgets('si el backend exige 2FA, envía el código y lleva a la pantalla del código', (tester) async {
      // Arrange
      await pumpWithProviders(
        tester,
        const LoginRegisterScreen(),
        // /users/2fa/check responde que sí hace falta; /users/2fa/send, que el código salió.
        api: (_) async => respuesta({'requires_2fa': true}),
      );

      // Act
      await tester.enterText(campo('E-mail'), 'ana@raccord.co');
      await tester.enterText(campo('Contraseña'), 'Clave\$egura1');
      await tester.tap(botonIngresar);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pantalla: /2fa'), findsOneWidget);
    });

    testWidgets('el correo se escribe siempre en minúscula', (tester) async {
      // Arrange
      await pumpWithProviders(tester, const LoginRegisterScreen());

      // Act
      await tester.enterText(campo('E-mail'), 'ANA@Raccord.CO');
      await tester.pump();

      // Assert
      expect(find.text('ana@raccord.co'), findsOneWidget);
    });
  });

  group('Registrar', () {
    Future<void> abrirRegistro(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(Tab, 'Registrar'));
      await tester.pumpAndSettle();
    }

    Future<void> llenarFormulario(WidgetTester tester, {required String contrasena, String? confirmacion}) async {
      const datos = {
        'Razón Social': 'cine sas',
        'Nº Documento': '900123',
        'Email Empresa': 'info@cine.co',
        'Nombres': 'ana',
        'Apellidos': 'ruiz',
        'Email Personal': 'ana@cine.co',
        'Celular': '3001234567',
      };
      for (final entrada in datos.entries) {
        await tester.enterText(campo(entrada.key), entrada.value);
      }
      await tester.enterText(campo('Contraseña'), contrasena);
      await tester.enterText(campo('Confirmar Contraseña'), confirmacion ?? contrasena);
      await tester.pump();
    }

    testWidgets('con el formulario vacío el botón está deshabilitado y explica por qué', (tester) async {
      // Arrange
      await pumpWithProviders(tester, const LoginRegisterScreen());

      // Act
      await abrirRegistro(tester);

      // Assert
      expect(deshabilitado(tester, botonRegistrar), isTrue);
      expect(find.text('Completa todos los campos requeridos para registrarte.'), findsOneWidget);
    });

    testWidgets('con una contraseña débil dice qué reglas le faltan', (tester) async {
      // Arrange
      await pumpWithProviders(tester, const LoginRegisterScreen());
      await abrirRegistro(tester);

      // Act: todo lleno, pero la contraseña solo tiene minúsculas
      await llenarFormulario(tester, contrasena: 'abc');

      // Assert
      expect(
        find.text('La contraseña debe cumplir: Mínimo 8 caracteres, Una letra mayúscula, Un número, Un carácter especial.'),
        findsOneWidget,
      );
      expect(deshabilitado(tester, botonRegistrar), isTrue);
    });

    testWidgets('si las contraseñas no coinciden, lo avisa', (tester) async {
      await pumpWithProviders(tester, const LoginRegisterScreen());
      await abrirRegistro(tester);

      await llenarFormulario(tester, contrasena: 'Clave\$egura1', confirmacion: 'Clave\$egura2');

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('sin aceptar los términos no deja registrar', (tester) async {
      await pumpWithProviders(tester, const LoginRegisterScreen());
      await abrirRegistro(tester);

      await llenarFormulario(tester, contrasena: 'Clave\$egura1');

      expect(find.text('Debes aceptar los Términos y Condiciones para registrarte.'), findsOneWidget);
      expect(deshabilitado(tester, botonRegistrar), isTrue);
    });

    testWidgets('con todo completo registra, inicia sesión y lleva a registrar el proyecto', (tester) async {
      // Arrange
      final peticiones = <http.Request>[];
      final session = await pumpWithProviders(
        tester,
        const LoginRegisterScreen(),
        peticiones: peticiones,
        api: (req) async => switch (req.url.path) {
          '/register' => respuesta({'id_user': 'u1'}),
          '/users/login' => respuesta({'access_token': 'jwt-123', 'usuario': usuarioJson}),
          _ => respuesta(null, success: false, status: 404),
        },
      );
      await abrirRegistro(tester);
      await llenarFormulario(tester, contrasena: 'Clave\$egura1');

      // Act: acepta los términos y envía
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(deshabilitado(tester, botonRegistrar), isFalse);
      await tester.tap(botonRegistrar);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pantalla: /registrar-proyecto'), findsOneWidget);
      expect(session.isAuthenticated, isTrue);
      expect(peticiones.map((r) => r.url.path), ['/register', '/users/login']);
    });
  });
}
