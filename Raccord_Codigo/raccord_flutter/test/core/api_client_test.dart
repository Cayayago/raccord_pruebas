// Capa Front — Cliente HTTP de la app (lib/core/api_client.dart).
// Regla: toda respuesta del backend se traduce a datos o a un
// ApiException con un mensaje que la persona entienda.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:raccord/core/api_exception.dart';

import '../helpers/fake_api.dart';

void main() {
  group('respuestas exitosas', () {
    test('devuelve solo el campo "data" del sobre', () async {
      // Arrange
      final fake = FakeApi((_) async => sobre({'id': 'esc-1'}));

      // Act
      final data = await fake.api.get('/scenes/esc-1');

      // Assert
      expect(data, {'id': 'esc-1'});
    });

    test('envía el token como Bearer', () async {
      final fake = FakeApi((_) async => sobre(null));

      await fake.api.get('/projects');

      expect(fake.ultima.headers['Authorization'], 'Bearer token-de-prueba');
    });

    test('no envía Authorization cuando auth es false', () async {
      final fake = FakeApi((_) async => sobre(null));

      await fake.api.post('/users/login', auth: false, body: {'mail': 'a@b.co'});

      expect(fake.ultima.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(fake.ultima.body), {'mail': 'a@b.co'});
    });

    test('no envía Authorization si todavía no hay token', () async {
      final fake = FakeApi((_) async => sobre(null), token: null);

      await fake.api.get('/projects');

      expect(fake.ultima.headers.containsKey('Authorization'), isFalse);
    });

    test('agrega los parámetros de consulta a la URL', () async {
      final fake = FakeApi((_) async => sobre([]));

      await fake.api.get('/fotos', query: {'pagina': 2});

      expect(fake.ultima.url.queryParameters, {'pagina': '2'});
    });

    test('put, patch y delete usan el método HTTP correcto', () async {
      final fake = FakeApi((_) async => sobre(null));

      await fake.api.put('/a', body: {'x': 1});
      await fake.api.patch('/b', body: {'y': 2});
      await fake.api.delete('/c');

      expect(fake.peticiones.map((r) => r.method), ['PUT', 'PATCH', 'DELETE']);
    });

    test('una respuesta 200 sin cuerpo devuelve null', () async {
      final fake = FakeApi((_) async => http.Response('', 200));

      expect(await fake.api.delete('/c'), isNull);
    });
  });

  group('errores', () {
    test('success=false se convierte en ApiException con mensaje y código', () async {
      // Arrange
      final fake = FakeApi((_) async => sobre(null, success: false, message: 'Escena no encontrada', error: 'SCENE_NOT_FOUND'));

      // Act / Assert
      await expectLater(
        fake.api.get('/scenes/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Escena no encontrada')
            .having((e) => e.errorCode, 'errorCode', 'SCENE_NOT_FOUND')),
      );
    });

    test('un 401 de FastAPI usa el "detail" como mensaje y marca no autorizado', () async {
      final fake = FakeApi((_) async => jsonResponse({'detail': 'Token inválido o expirado'}, status: 401));

      await expectLater(
        fake.api.get('/projects'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Token inválido o expirado')
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('un 422 de Pydantic muestra el primer mensaje de validación', () async {
      final fake = FakeApi((_) async => jsonResponse({
            'detail': [
              {'msg': 'String should have at least 8 characters'},
            ],
          }, status: 422));

      await expectLater(
        fake.api.post('/register'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'String should have at least 8 characters')),
      );
    });

    test('un error sin JSON (proxy caído) da un mensaje genérico con el código', () async {
      final fake = FakeApi((_) async => http.Response('<html>502</html>', 502));

      await expectLater(
        fake.api.get('/projects'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.message, 'message', contains('502'))),
      );
    });

    test('un 403 también se considera no autorizado', () {
      expect(ApiException('x', statusCode: 403).isUnauthorized, isTrue);
      expect(ApiException('x', statusCode: 404).isUnauthorized, isFalse);
      expect(ApiException('Sin conexión').toString(), 'Sin conexión');
    });
  });

  group('archivos', () {
    test('getBytes devuelve los bytes crudos del PDF', () async {
      final fake = FakeApi((_) async => http.Response.bytes([37, 80, 68, 70], 200));

      expect(await fake.api.getBytes('/scripts/g-1/archivo'), [37, 80, 68, 70]);
    });

    test('getBytes con error usa el detail del backend', () async {
      final fake = FakeApi((_) async => jsonResponse({'detail': 'Guion no encontrado'}, status: 404));

      await expectLater(
        fake.api.getBytes('/scripts/x/archivo'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Guion no encontrado')),
      );
    });

    test('postFile envía multipart con el archivo y los campos de texto', () async {
      // Arrange
      final fake = FakeApi((_) async => sobre({'id_foto': 'f-1'}));

      // Act
      final data = await fake.api.postFile(
        '/scenes/esc-1/fotos',
        fieldName: 'file',
        bytes: [1, 2, 3],
        filename: 'foto.jpg',
        contentType: 'image/jpeg',
        fields: {'tipo_foto': 'Prueba'},
      );

      // Assert
      expect(data, {'id_foto': 'f-1'});
      final req = fake.ultima;
      expect(req.headers['content-type'], startsWith('multipart/form-data'));
      expect(req.headers['Authorization'], 'Bearer token-de-prueba');
      expect(req.body, contains('name="tipo_foto"'));
      expect(req.body, contains('filename="foto.jpg"'));
    });
  });
}
