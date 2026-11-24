// Capa Front — más servicios (lib/services) y modelos pequeños.
// El backend es un doble (MockClient vía FakeApi): se verifica QUÉ pide la
// app (ruta, método, cuerpo) y CÓMO interpreta la respuesta.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:raccord/core/api_config.dart';
import 'package:raccord/models/catalog.dart';
import 'package:raccord/models/notification.dart';
import 'package:raccord/models/scene.dart';
import 'package:raccord/services/department_service.dart';
import 'package:raccord/services/gallery_service.dart';
import 'package:raccord/services/notification_service.dart';
import 'package:raccord/services/scene_service.dart';
import 'package:raccord/services/user_service.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _foto(String id) => {
      'id_foto': id,
      'id_escena': 'e1',
      'tipo_foto': 'Prueba',
      'archivo_nombre': '$id.jpg',
      'archivo_tamano': 10,
    };

void main() {
  group('GalleryService', () {
    test('byScene, all y papelera piden la ruta correcta y leen la lista', () async {
      final fake = FakeApi((_) async => sobre([_foto('f1'), _foto('f2')]));
      final servicio = GalleryService(fake.api);

      final deEscena = await servicio.byScene('e1');
      expect(fake.ultima.url.path, '/scenes/e1/fotos');
      final delProyecto = await servicio.all('p1');
      expect(fake.ultima.url.path, '/fotos/project/p1');
      final enPapelera = await servicio.papelera('p1');
      expect(fake.ultima.url.path, '/fotos/papelera/p1');

      expect(deEscena.map((f) => f.idFoto), ['f1', 'f2']);
      expect(delProyecto, hasLength(2));
      expect(enPapelera, hasLength(2));
    });

    test('search manda texto, página y tamaño, y lee la página', () async {
      final fake = FakeApi((_) async => sobre({
            'items': [_foto('f1')],
            'total': 41,
            'page': 2,
            'total_pages': 3,
          }));

      final pagina = await GalleryService(fake.api).search('p1', q: 'Laura López', page: 2, pageSize: 20);

      expect(fake.ultima.url.path, '/fotos/project/p1/buscar');
      expect(fake.ultima.url.queryParameters, {'q': 'Laura López', 'page': '2', 'page_size': '20'});
      expect(pagina.items.single.idFoto, 'f1');
      expect([pagina.total, pagina.page, pagina.totalPages], [41, 2, 3]);
    });

    test('search sin texto no manda q y usa valores por defecto si faltan', () async {
      final fake = FakeApi((_) async => sobre({'items': []}));

      final pagina = await GalleryService(fake.api).search('p1');

      expect(fake.ultima.url.queryParameters.containsKey('q'), isFalse);
      expect([pagina.total, pagina.page, pagina.totalPages], [0, 1, 1]);
    });

    test('update, delete, restaurar y eliminarDefinitivo usan el método de cada acción', () async {
      final fake = FakeApi((_) async => sobre(_foto('f1')));
      final servicio = GalleryService(fake.api);

      final editada = await servicio.update('f1', {'descripcion': 'Plano medio'});
      expect(fake.ultima.method, 'PATCH');
      expect(jsonDecode(fake.ultima.body), {'descripcion': 'Plano medio'});
      expect(editada.idFoto, 'f1');

      await servicio.delete('f1');
      expect([fake.ultima.method, fake.ultima.url.path], ['DELETE', '/fotos/f1']);

      await servicio.restaurar('f1');
      expect([fake.ultima.method, fake.ultima.url.path], ['POST', '/fotos/f1/restaurar']);

      await servicio.eliminarDefinitivo('f1');
      expect([fake.ultima.method, fake.ultima.url.path], ['DELETE', '/fotos/f1/definitivo']);
    });

    test('archivoBytes descarga el binario tal cual', () async {
      final fake = FakeApi((_) async => http.Response.bytes([7, 8, 9], 200));

      expect(await GalleryService(fake.api).archivoBytes('f1'), [7, 8, 9]);
      expect(fake.ultima.url.path, '/fotos/f1/archivo');
    });
  });

  group('SceneService', () {
    test('byScript y get leen las escenas', () async {
      final fake = FakeApi((req) async => req.url.path.contains('/script/')
          ? sobre([
              {'id_escena': 'e1', 'numero_de_escena': '1', 'encabezado': 'INT. CASA'},
            ])
          : sobre({'id_escena': 'e2', 'numero_de_escena': '2', 'encabezado': 'EXT. CALLE'}));
      final servicio = SceneService(fake.api);

      final delGuion = await servicio.byScript('g1');
      final una = await servicio.get('e2');

      expect(fake.peticiones.map((r) => r.url.path), ['/scenes/script/g1', '/scenes/e2']);
      expect(delGuion.single.numeroDeEscena, '1');
      expect(una.encabezado, 'EXT. CALLE');
    });

    test('create devuelve la escena del servidor, o la misma si no vino cuerpo', () async {
      final escena = Scene.fromJson({'id_escena': '', 'numero_de_escena': '7', 'encabezado': 'INT. BAR'});

      final conCuerpo = FakeApi((_) async => sobre({'id_escena': 'e7', 'numero_de_escena': '7', 'encabezado': 'INT. BAR'}));
      final creada = await SceneService(conCuerpo.api).create(escena);
      expect(creada.idEscena, 'e7');
      expect(jsonDecode(conCuerpo.ultima.body)['numero_de_escena'], '7');

      final sinCuerpo = FakeApi((_) async => sobre(null));
      expect(identical(await SceneService(sinCuerpo.api).create(escena), escena), isTrue);
    });

    test('updatePartial, delete, cast y removeFromCast', () async {
      final fake = FakeApi((req) async => req.method == 'GET'
          ? sobre([
              {'id_personaje': 'p1', 'nombre': 'Laura'},
            ])
          : sobre(null));
      final servicio = SceneService(fake.api);

      await servicio.updatePartial('e1', {'estado': 'Finalizada'});
      expect([fake.ultima.method, jsonDecode(fake.ultima.body)], ['PATCH', {'estado': 'Finalizada'}]);
      await servicio.delete('e1');
      expect([fake.ultima.method, fake.ultima.url.path], ['DELETE', '/scenes/e1']);
      final reparto = await servicio.cast('e1');
      expect(reparto.single['nombre'], 'Laura');
      await servicio.removeFromCast('e1', 'p1');
      expect([fake.ultima.method, fake.ultima.url.path], ['DELETE', '/scenes/e1/cast/p1']);
    });
  });

  group('UserService', () {
    test('get y byProject leen usuarios', () async {
      final fake = FakeApi((req) async => req.url.path.contains('/project/')
          ? sobre([
              {'id_user': 'u1', 'nombre': 'Ana', 'apellido': 'Ruiz', 'mail': 'ana@b.co'},
            ])
          : sobre({'id_user': 'u2', 'nombre': 'Luis', 'apellido': 'Gil', 'mail': 'luis@b.co'}));
      final servicio = UserService(fake.api);

      final uno = await servicio.get('u2');
      final equipo = await servicio.byProject('p1');

      expect(uno.nombreCompleto, 'Luis Gil');
      expect(equipo.single.mail, 'ana@b.co');
      expect(fake.ultima.url.path, '/users/project/p1');
    });

    test('las ediciones van al endpoint correcto con el cuerpo esperado', () async {
      final fake = FakeApi((_) async => sobre(null));
      final servicio = UserService(fake.api);

      await servicio.updatePartial('u1', {'nombre': 'Ana'});
      expect([fake.ultima.method, fake.ultima.url.path], ['PATCH', '/users/u1']);

      await servicio.setEstado('u1', 'suspendido', 'p1');
      expect(jsonDecode(fake.ultima.body), {'estado': 'suspendido', 'id_project': 'p1'});

      await servicio.updateOwnProfile({'msisdn': '300'});
      expect(fake.ultima.url.path, '/users/me');

      await servicio.changePassword(contrasenaActual: 'Vieja123*', nuevaContrasena: 'Nueva123*');
      expect(jsonDecode(fake.ultima.body), {'contrasena_actual': 'Vieja123*', 'nueva_contrasena': 'Nueva123*'});

      await servicio.uploadOwnPhoto(bytes: [1, 2], filename: 'yo.png', contentType: 'image/png');
      expect(fake.ultima.url.path, '/users/me/foto');
      expect(fake.ultima.body, contains('filename="yo.png"'));
    });

    test('photoBytes descarga la foto de perfil', () async {
      final fake = FakeApi((_) async => http.Response.bytes([1, 2, 3], 200));

      expect(await UserService(fake.api).photoBytes('u1'), [1, 2, 3]);
      expect(fake.ultima.url.path, '/users/u1/foto');
    });
  });

  group('NotificationService', () {
    test('all lee las notificaciones con sus departamentos', () async {
      final fake = FakeApi((_) async => sobre([
            {
              'id_notificacion': 'n1',
              'id_project': 'p1',
              'tipo_alcance': 'especifica',
              'origen': 'plan_rodaje',
              'texto': 'Cambio de llamado',
              'tiene_foto': true,
              'leida': false,
              'fecha_creacion': '2026-11-20T08:30:00',
              'departamentos': [
                {'id_departamento': 'd1', 'nombre': 'Arte'},
              ],
            },
          ]));

      final lista = await NotificationService(fake.api).all('p1');

      final n = lista.single;
      expect(fake.ultima.url.path, '/notificaciones/project/p1');
      expect([n.tipoAlcance, n.origen, n.tieneFoto, n.leida], ['especifica', kOrigenPlanRodaje, true, false]);
      expect(n.fechaCreacion, DateTime(2026, 11, 20, 8, 30));
      expect(n.departamentos.single.nombre, 'Arte');
    });

    test('unreadCount lee el contador y responde 0 si no viene un mapa', () async {
      final conDato = FakeApi((_) async => sobre({'no_leidas': 4}));
      final sinDato = FakeApi((_) async => sobre(null));

      expect(await NotificationService(conDato.api).unreadCount('p1'), 4);
      expect(await NotificationService(sinDato.api).unreadCount('p1'), 0);
    });

    test('crear específica manda los departamentos; general no', () async {
      final fake = FakeApi((_) async => sobre({'id_notificacion': 'n9', 'texto': 'Hola'}));
      final servicio = NotificationService(fake.api);

      await servicio.crear('p1', tipoAlcance: kAlcanceEspecifica, idsDepartamentos: ['d1', 'd2'], texto: 'Hola');
      expect(fake.ultima.body, contains('d1,d2'));

      final general = await servicio.crear('p1', tipoAlcance: kAlcanceGeneral, idsDepartamentos: ['d1'], texto: 'Hola');
      expect(fake.ultima.body, isNot(contains('name="departamentos"')));
      expect(general.idNotificacion, 'n9');
    });

    test('crear sin confirmación del servidor lanza un error', () async {
      final fake = FakeApi((_) async => sobre(null));

      await expectLater(
        NotificationService(fake.api).crear('p1', tipoAlcance: kAlcanceGeneral, texto: 'x'),
        throwsA(isA<Exception>()),
      );
    });

    test('marcarLeida y fotoBytes', () async {
      final fake = FakeApi((req) async =>
          req.url.path.endsWith('/foto') ? http.Response.bytes([5], 200) : sobre(null));
      final servicio = NotificationService(fake.api);

      await servicio.marcarLeida('n1');
      expect([fake.ultima.method, fake.ultima.url.path], ['POST', '/notificaciones/n1/leer']);
      expect(await servicio.fotoBytes('n1'), [5]);
    });
  });

  group('DepartmentService', () {
    test('all y create', () async {
      final fake = FakeApi((req) async => req.method == 'GET'
          ? sobre([
              {'id_departamento': 'd1', 'nombre': 'Arte', 'ubicacion': 'Set A'},
            ])
          : sobre({'id_departamento': 'd2', 'nombre': 'Vestuario', 'ubicacion': 'Set B'}));
      final servicio = DepartmentService(fake.api);

      final todos = await servicio.all();
      final nuevo = await servicio.create('Vestuario', 'Set B');

      expect(todos.single.nombre, 'Arte');
      expect(jsonDecode(fake.ultima.body), {'nombre': 'Vestuario', 'ubicacion': 'Set B'});
      expect(nuevo.idDepartamento, 'd2');
    });
  });

  group('Modelos de catálogo y notificación', () {
    test('RoleModel lee el JSON y por defecto queda activo', () {
      final rol = RoleModel.fromJson({'id_rol': 1004, 'nombre': 'Jefe', 'nivel_jerarquia': '3', 'descripcion': 'x'});
      final vacio = RoleModel.fromJson({});

      expect([rol.idRol, rol.nombre, rol.nivelJerarquia, rol.descripcion, rol.activo], [1004, 'Jefe', '3', 'x', true]);
      expect([vacio.idRol, vacio.nombre], [0, '']);
    });

    test('ClientModel lee el JSON y usa textos vacíos si faltan', () {
      final cliente = ClientModel.fromJson({
        'id_client': 'c1',
        'document': 'NIT',
        'razon_social': 'Cine SAS',
        'representante_legal': 'Ana',
        'email': 'info@cine.co',
      });
      final vacio = ClientModel.fromJson({});

      expect([cliente.idClient, cliente.razonSocial, cliente.email], ['c1', 'Cine SAS', 'info@cine.co']);
      expect([vacio.idClient, vacio.document, vacio.representanteLegal], [null, '', '']);
    });

    test('AppNotification sin datos usa general, manual y sin departamentos', () {
      final n = AppNotification.fromJson({});

      expect([n.tipoAlcance, n.origen, n.texto, n.tieneFoto, n.leida], [kAlcanceGeneral, kOrigenManual, '', false, false]);
      expect(n.fechaCreacion, isNull);
      expect(n.departamentos, isEmpty);
    });
  });

  group('ApiConfig', () {
    test('override quita la barra final y gana sobre el valor por defecto', () {
      ApiConfig.override('http://192.168.1.10:8000/');
      expect(ApiConfig.baseUrl, 'http://192.168.1.10:8000');

      ApiConfig.override('');
      expect(ApiConfig.baseUrl, 'http://127.0.0.1:8000');
    });
  });
}
