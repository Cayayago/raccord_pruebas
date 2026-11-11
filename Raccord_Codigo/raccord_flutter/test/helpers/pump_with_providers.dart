// Helper COMPARTIDO de la semana 3 (equivale al `renderWithProviders` del
// reto en React): monta una pantalla con todo lo que necesita para
// funcionar en un test, sin backend real.
//
//   final session = await pumpWithProviders(tester, const LoginRegisterScreen(),
//       api: (req) async => respuesta(...));
//
// - AuthSession viene con un MockClient: la pantalla nunca sale a la red
//   (equivale a `vi.mock` del cliente HTTP).
// - MaterialApp con rutas falsas: si la pantalla navega, el test ve el
//   texto "Pantalla: <ruta>" (equivale a MemoryRouter).
// - Ventana grande para que los formularios largos quepan sin scroll.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:raccord/core/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rutas a las que puede navegar una pantalla. Cada una solo muestra
/// "Pantalla: <ruta>" para que el test compruebe a dónde se fue.
const rutasFalsas = [
  '/proyectos',
  '/2fa',
  '/registrar-proyecto',
  '/olvide-password',
  '/login',
  '/dashboard',
];

Future<AuthSession> pumpWithProviders(
  WidgetTester tester,
  Widget pantalla, {
  Future<http.Response> Function(http.Request req)? api,
  List<http.Request>? peticiones,
}) async {
  SharedPreferences.setMockInitialValues({});

  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final session = AuthSession(
    httpClient: MockClient((req) {
      peticiones?.add(req);
      if (api != null) return api(req);
      // Si un test no esperaba llamadas a la API, que falle de forma visible.
      return Future.value(respuesta(null, success: false, message: 'API no simulada en este test', status: 500));
    }),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthSession>.value(
      value: session,
      child: MaterialApp(
        home: pantalla,
        routes: {
          for (final ruta in rutasFalsas) ruta: (_) => Scaffold(body: Text('Pantalla: $ruta')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

/// Respuesta con el sobre estándar de la API ({success, message, data, error}).
http.Response respuesta(dynamic data, {bool success = true, String message = 'ok', String? error, int status = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode({'success': success, 'message': message, 'data': data, 'error': error})),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Campo de texto por su ETIQUETA visible (equivale a getByLabelText):
/// AppTextField dibuja la etiqueta como Text encima del TextFormField.
Finder campo(String etiqueta) => find.descendant(
      of: find.ancestor(of: find.text(etiqueta), matching: find.byType(Column)).first,
      matching: find.byType(TextFormField),
    );
