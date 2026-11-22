import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raccord/core/api_client.dart';

/// ApiClient conectado a un servidor FALSO (MockClient de package:http):
/// ninguna prueba unitaria sale a la red. [handler] decide qué responde
/// el "backend" para cada petición, y [peticiones] guarda lo que la app
/// envió para poder verificarlo en el Assert.
class FakeApi {
  final List<http.Request> peticiones = [];
  late final ApiClient api;

  FakeApi(Future<http.Response> Function(http.Request req) handler, {String? token = 'token-de-prueba'}) {
    api = ApiClient(
      tokenProvider: () => token,
      httpClient: MockClient((req) {
        peticiones.add(req);
        return handler(req);
      }),
    );
  }

  http.Request get ultima => peticiones.last;
}

/// Respuesta con el sobre estándar de la API de Raccord
/// ({success, message, data, error} — ver app/utils/response.py).
http.Response sobre(
  dynamic data, {
  bool success = true,
  String message = 'ok',
  String? error,
  int status = 200,
}) {
  return jsonResponse({'success': success, 'message': message, 'data': data, 'error': error}, status: status);
}

/// Respuesta JSON en UTF-8 (http.Response(String) usa latin1 y rompe con tildes).
http.Response jsonResponse(Object body, {int status = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
