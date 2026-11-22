// Capa Front — Servicios que hablan con la API (lib/services).
// El backend es un doble (MockClient): se verifica QUÉ pide la app y
// CÓMO interpreta la respuesta, sin depender del servidor real.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/api_exception.dart';
import 'package:raccord/services/auth_service.dart';
import 'package:raccord/services/gallery_service.dart';
import 'package:raccord/services/module_access_service.dart';
import 'package:raccord/services/project_service.dart';
import 'package:raccord/services/role_service.dart';
import 'package:raccord/services/scene_service.dart';

import '../helpers/fake_api.dart';

void main() {
  group('AuthService', () {
    test('login devuelve el token y el usuario de la sesión', () async {
      // Arrange
      final fake = FakeApi((_) async => sobre({
            'access_token': 'jwt-123',
            'usuario': {'id_user': 'u1', 'nombre': 'Ana', 'apellido': 'Ruiz', 'mail': 'ana@b.co', 'id_rol': 1004},
          }));

      // Act
      final resultado = await AuthService(fake.api).login('ana@b.co', 'Clave123');

      // Assert
      expect(resultado.token, 'jwt-123');
      expect(resultado.user.idRol, 1004);
      expect(fake.ultima.url.path, '/users/login');
      expect(fake.ultima.headers.containsKey('Authorization'), isFalse);
    });

    test('check2faRequired solo es verdadero si el backend dice true', () async {
      final fake = FakeApi((_) async => sobre({'requires_2fa': false}));

      expect(await AuthService(fake.api).check2faRequired('a@b.co', 'cel-1', 'x'), isFalse);
    });

    test('verify2faCode marca el dispositivo como verificado', () async {
      final fake = FakeApi((_) async => sobre({
            'access_token': 't',
            'usuario': {'id_user': 'u1'},
            'device_verified': true,
          }));

      final resultado = await AuthService(fake.api).verify2faCode('a@b.co', '123456', 'cel-1', 'x');

      expect(resultado.deviceVerified, isTrue);
    });

    test('register no envía los campos opcionales vacíos', () async {
      final fake = FakeApi((_) async => sobre(null));

      await AuthService(fake.api).register(
        razonSocial: 'Cine SAS',
        representanteLegal: 'Ana',
        emailEmpresa: 'info@cine.co',
        address: '',
        document: 'NIT',
        idDocument: '900',
        nombre: 'Ana',
        apellido: 'Ruiz',
        mail: 'ana@cine.co',
        msisdn: '300',
        contrasena: 'Clave123',
      );

      final body = jsonDecode(fake.ultima.body) as Map;
      expect(body.containsKey('address'), isFalse);
      expect(body['razon_social'], 'Cine SAS');
    });

    test('un login fallido propaga el código de error del backend', () async {
      final fake = FakeApi((_) async =>
          sobre(null, success: false, message: 'Verifica tu correo y tu contraseña', error: 'INVALID_CREDENTIALS'));

      await expectLater(
        AuthService(fake.api).login('ana@b.co', 'mala'),
        throwsA(isA<ApiException>().having((e) => e.errorCode, 'errorCode', 'INVALID_CREDENTIALS')),
      );
    });
  });

  group('ProjectService', () {
    const proyectoJson = {
      'id_project': 'p1',
      'project_name': 'Raccord',
      'formato_de_produccion': 'Serie',
      'genero': 'Drama',
      'id_client': 'c1',
    };

    test('quien crea el proyecto queda como Administrador (1001)', () async {
      final fake = FakeApi((_) async => sobre(proyectoJson));

      final proyecto = await ProjectService(fake.api).createAndLink(
        projectName: 'Raccord',
        formatoDeProduccion: 'Serie',
        genero: 'Drama',
        idClient: 'c1',
        idUser: 'u1',
      );

      expect(proyecto.idRol, 1001);
    });

    test('si el backend solo devuelve el id, consulta el proyecto completo', () async {
      // Arrange: el POST responde solo el id; el GET, el proyecto
      final fake = FakeApi((req) async => req.method == 'POST' ? sobre('p1') : sobre(proyectoJson));

      // Act
      final proyecto = await ProjectService(fake.api).createAndLink(
        projectName: 'Raccord',
        formatoDeProduccion: 'Serie',
        genero: 'Drama',
        idClient: 'c1',
        idUser: 'u1',
        sinopsis: '',
      );

      // Assert
      expect(fake.peticiones.map((r) => '${r.method} ${r.url.path}'), ['POST /projects/create', 'GET /projects/p1']);
      expect(proyecto.projectName, 'Raccord');
      expect(proyecto.idRol, 1001);
      expect((jsonDecode(fake.peticiones.first.body) as Map).containsKey('sinopsis'), isFalse);
    });

    test('myProjects pide los proyectos del usuario con su rol en cada uno', () async {
      final fake = FakeApi((_) async => sobre([
            {'id_project': 'p1', 'id_rol': 1004},
          ]));

      final proyectos = await ProjectService(fake.api).myProjects('u1');

      expect(fake.ultima.url.path, '/users/u1/projects');
      expect(proyectos.single.idRol, 1004);
    });
  });

  group('SceneService', () {
    test('all pide las escenas DEL PROYECTO activo', () async {
      final fake = FakeApi((_) async => sobre([
            {'id_escena': 'e1', 'numero_de_escena': '1', 'encabezado': 'INT. CASA - DÍA'},
          ]));

      final escenas = await SceneService(fake.api).all('proj-1');

      expect(fake.ultima.url.path, '/scenes/project/proj-1');
      expect(escenas.single.encabezado, 'INT. CASA - DÍA');
    });

    test('addToCast envía el personaje a la escena', () async {
      final fake = FakeApi((_) async => sobre(null));

      await SceneService(fake.api).addToCast('e1', 'p1');

      expect(fake.ultima.url.path, '/scenes/e1/cast');
      expect(jsonDecode(fake.ultima.body), {'id_personaje': 'p1'});
    });
  });

  group('GalleryService.upload', () {
    test('envía los datos de la foto y devuelve la foto creada', () async {
      final fake = FakeApi((_) async => sobre({
            'id_foto': 'f1',
            'id_escena': 'e1',
            'tipo_foto': 'Prueba',
            'archivo_nombre': 'a.jpg',
            'archivo_tamano': 3,
          }));

      final foto = await GalleryService(fake.api).upload(
        'e1',
        tipoFoto: 'Prueba',
        personajeCodigo: '',
        bytes: [1, 2, 3],
        filename: 'a.jpg',
        contentType: 'image/jpeg',
      );

      expect(foto.idFoto, 'f1');
      expect(fake.ultima.body, isNot(contains('name="personaje_codigo"'))); // vacío: no se envía
    });

    test('si el servidor no confirma la subida, lanza un error entendible', () async {
      final fake = FakeApi((_) async => sobre(null));

      await expectLater(
        GalleryService(fake.api).upload('e1', tipoFoto: 'Prueba', bytes: [1], filename: 'a.jpg', contentType: 'image/jpeg'),
        throwsA(isA<ApiException>().having((e) => e.errorCode, 'errorCode', 'UPLOAD_NO_RESPONSE')),
      );
    });
  });

  group('ModuleAccessService', () {
    test('list lee los módulos de la respuesta', () async {
      final fake = FakeApi((_) async => sobre({
            'modulos': [
              {'modulo': 'galeria', 'nivel_efectivo': 'comentar'},
            ],
          }));

      final accesos = await ModuleAccessService(fake.api).list('p1', 'u1');

      expect(fake.ultima.url.path, '/projects/p1/users/u1/module-access');
      expect(accesos.single.nivelEfectivo, 'comentar');
    });

    test('set usa PUT con el nivel', () async {
      final fake = FakeApi((_) async => sobre(null));

      await ModuleAccessService(fake.api).set('p1', 'u1', 'galeria', 'ver');

      expect(fake.ultima.method, 'PUT');
      expect(jsonDecode(fake.ultima.body), {'nivel': 'ver'});
    });
  });

  test('RoleService.invite serializa a las personas invitadas', () async {
    final fake = FakeApi((_) async => sobre({'usuarios_creados': [], 'errores': []}));

    await RoleService(fake.api).invite(
      invitados: [InviteItem(nombreCompleto: 'Ana Ruiz', mail: 'ana@b.co', idDepartamento: 'd1', idRol: 1004)],
      idProject: 'p1',
      idClient: 'c1',
    );

    final body = jsonDecode(fake.ultima.body) as Map;
    expect(body['invitados'], [
      {'nombre_completo': 'Ana Ruiz', 'mail': 'ana@b.co', 'id_departamento': 'd1', 'id_rol': 1004},
    ]);
  });
}
