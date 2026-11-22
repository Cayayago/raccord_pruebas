// Capa Front — Sesión y permisos por proyecto (lib/core/session.dart) y
// cambios pendientes del Plan de Rodaje (lib/core/plan_change_tracker.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/permissions.dart';
import 'package:raccord/core/plan_change_tracker.dart';
import 'package:raccord/core/session.dart';
import 'package:raccord/models/project.dart';
import 'package:raccord/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionUser usuario({int idRol = Roles.administrador}) =>
    SessionUser(idUser: 'u1', nombre: 'Ana', apellido: 'Ruiz', mail: 'ana@b.co', idRol: idRol);

Project proyecto({int? idRol}) => Project(
      idProject: 'p1',
      projectName: 'Raccord',
      formatoDeProduccion: 'Serie',
      genero: 'Drama',
      idClient: 'c1',
      idRol: idRol,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthSession', () {
    test('sin proyecto activo usa el rol global de la cuenta', () async {
      final session = AuthSession();

      await session.setSession('jwt', usuario(idRol: Roles.administrador));

      expect(session.isAuthenticated, isTrue);
      expect(session.can('create_project'), isTrue);
    });

    test('con proyecto activo manda el rol DENTRO del proyecto', () async {
      // Arrange: Administrador en su cuenta, pero Usuario en este proyecto
      final session = AuthSession();
      await session.setSession('jwt', usuario(idRol: Roles.administrador));

      // Act
      await session.setProject(proyecto(idRol: Roles.usuario));

      // Assert
      expect(session.hasProject, isTrue);
      expect(session.can('upload_photos'), isFalse);
    });

    test('la sesión se recupera al reiniciar la app', () async {
      // Arrange: una sesión guardada
      final primera = AuthSession();
      await primera.setSession('jwt-guardado', usuario(idRol: Roles.onset));

      // Act: la app se vuelve a abrir
      final segunda = AuthSession();
      await segunda.bootstrap();

      // Assert
      expect(segunda.ready, isTrue);
      expect(segunda.token, 'jwt-guardado');
      expect(segunda.user!.nombreCompleto, 'Ana Ruiz');
      expect(segunda.deviceId, isNotEmpty);
    });

    test('el device_id se conserva entre reinicios (2FA "recordar dispositivo")', () async {
      final a = AuthSession();
      await a.bootstrap();
      final b = AuthSession();
      await b.bootstrap();

      expect(b.deviceId, a.deviceId);
    });

    test('logout borra token, usuario y proyecto también del almacenamiento', () async {
      final session = AuthSession();
      await session.setSession('jwt', usuario());
      await session.setProject(proyecto(idRol: Roles.director));

      await session.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(session.isAuthenticated, isFalse);
      expect(session.hasProject, isFalse);
      expect(prefs.getString('raccord_token'), isNull);
    });

    test('clearProject vuelve a la selección de proyecto sin cerrar sesión', () async {
      final session = AuthSession();
      await session.setSession('jwt', usuario());
      await session.setProject(proyecto(idRol: Roles.director));

      await session.clearProject();

      expect(session.isAuthenticated, isTrue);
      expect(session.projectRole, isNull);
    });

    test('updateUserNames cambia el nombre mostrado', () async {
      final session = AuthSession();
      await session.setSession('jwt', usuario());

      await session.updateUserNames('María', 'Gómez');

      expect(session.user!.nombreCompleto, 'María Gómez');
    });

    test('canSeeModule no oculta nada mientras no llegan los accesos', () {
      expect(AuthSession().canSeeModule('galeria'), isTrue);
    });
  });

  group('PlanChangeTracker', () {
    late AuthSession director;

    setUp(() async {
      director = AuthSession();
      await director.setSession('jwt', usuario());
      await director.setProject(proyecto(idRol: Roles.director)); // puede publicar notificaciones
    });

    test('registra un cambio con su valor anterior y el nuevo', () {
      final tracker = PlanChangeTracker();

      tracker.record(director, key: 'hora-e1', descripcion: 'Escena 1, hora', antes: '07:00', despues: '08:00');

      expect(tracker.count, 1);
      expect(tracker.buildText(), contains('«07:00» → «08:00»'));
    });

    test('dos ediciones del mismo campo conservan el valor ORIGINAL', () {
      final tracker = PlanChangeTracker();

      tracker.record(director, key: 'hora-e1', descripcion: 'Hora', antes: '07:00', despues: '08:00');
      tracker.record(director, key: 'hora-e1', descripcion: 'Hora', antes: '08:00', despues: '09:00');

      expect(tracker.buildText(), contains('«07:00» → «09:00»'));
    });

    test('si el campo vuelve a su valor original, ya no hay nada que notificar', () {
      final tracker = PlanChangeTracker();

      tracker.record(director, key: 'hora-e1', descripcion: 'Hora', antes: '07:00', despues: '08:00');
      tracker.record(director, key: 'hora-e1', descripcion: 'Hora', antes: '08:00', despues: '07:00');

      expect(tracker.hasPending, isFalse);
    });

    test('un cambio sin valores se muestra solo con su descripción', () {
      final tracker = PlanChangeTracker();

      tracker.record(director, key: 'orden', descripcion: 'Se reordenó el día 2', conValores: false);

      expect(tracker.buildText(), endsWith('• Se reordenó el día 2'));
    });

    test('no registra cambios de quien no puede publicar notificaciones', () async {
      final onset = AuthSession();
      await onset.setSession('jwt', usuario(idRol: Roles.onset));
      await onset.setProject(proyecto(idRol: Roles.onset));
      final tracker = PlanChangeTracker();

      tracker.record(onset, key: 'k', descripcion: 'd', antes: 'a', despues: 'b');

      expect(tracker.hasPending, isFalse);
    });

    test('clear descarta los cambios pendientes', () {
      final tracker = PlanChangeTracker()..record(director, key: 'k', descripcion: 'd', antes: 'a', despues: 'b');

      tracker.clear();

      expect(tracker.count, 0);
    });

    test('si no se pudo enviar la notificación, los cambios NO se pierden', () async {
      // En las pruebas no hay backend: el envío falla a propósito
      final tracker = PlanChangeTracker()..record(director, key: 'k', descripcion: 'd', antes: 'a', despues: 'b');

      final enviado = await tracker.flush(director);

      expect(enviado, isFalse);
      expect(tracker.hasPending, isTrue);
    });

    test('flush sin cambios no hace nada y responde éxito', () async {
      expect(await PlanChangeTracker().flush(director), isTrue);
    });
  });
}
