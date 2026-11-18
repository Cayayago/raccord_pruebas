// Semana 3 — Front: CrewListScreen (Javier).
//
// Directorio de personas del proyecto (lib/screens/characters/crew_list_screen.dart):
// lista con estados de carga/vacío/datos/error, buscador por nombre, filtro
// por departamento y botón "Agregar Persona" que solo ve quien puede invitar.
// Se prueba como la usa una persona: busca por texto visible, escribe, toca
// y mira qué aparece. El backend es un MockClient (ver
// test/helpers/pump_with_providers.dart, helper compartido con Deiver).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:raccord/core/permissions.dart';
import 'package:raccord/core/session.dart';
import 'package:raccord/models/project.dart';
import 'package:raccord/models/user.dart';
import 'package:raccord/screens/characters/crew_list_screen.dart';

import '../helpers/pump_with_providers.dart';

const personas = <Map<String, dynamic>>[
  {
    'id_user': 'u1',
    'nombre': 'Ana',
    'apellido': 'Ruiz',
    'mail': 'ana@raccord.co',
    'msisdn': '3001112233',
    'estado': 'activo',
    'id_departamento': 'd1',
  },
  {
    'id_user': 'u2',
    'nombre': 'Luis',
    'apellido': 'Pérez',
    'mail': 'luis@raccord.co',
    'estado': 'pendiente',
    'id_departamento': 'd2',
  },
];

const departamentos = <Map<String, dynamic>>[
  {'id_departamento': 'd1', 'nombre': 'Arte', 'ubicacion': 'Set'},
  {'id_departamento': 'd2', 'nombre': 'Sonido', 'ubicacion': 'Set'},
];

/// API simulada: responde según la ruta, igual que lo haría el backend.
/// [usuarios] devuelve la lista de personas del proyecto "p1"; el resto de
/// rutas (catálogos, accesos por módulo) responden vacío.
Future<http.Response> Function(http.Request) apiCon({
  List<Map<String, dynamic>> usuarios = personas,
  http.Response? respuestaUsuarios,
}) {
  return (req) async {
    final ruta = req.url.path;
    if (ruta.endsWith('/users/project/p1')) return respuestaUsuarios ?? respuesta(usuarios);
    if (ruta.endsWith('/departments')) return respuesta(departamentos);
    return respuesta([]);
  };
}

/// Deja la sesión iniciada, con un rol efectivo en el proyecto "p1", ANTES de
/// montar la pantalla (la pantalla lee session.projectId en initState).
Future<void> Function(AuthSession) conRol(int rol) {
  return (session) async {
    await session.setSession(
      'token-de-prueba',
      SessionUser(idUser: 'u0', nombre: 'Admin', apellido: 'Prueba', mail: 'admin@raccord.co', idRol: rol),
    );
    await session.setProject(
      Project(
        idProject: 'p1',
        projectName: 'Proyecto de prueba',
        formatoDeProduccion: 'Cortometraje',
        genero: 'Drama',
        idClient: 'c1',
        idRol: rol,
      ),
    );
  };
}

/// Las filas de la tabla viven dentro del ListView; así no se confunden con el
/// texto del desplegable de departamentos ni con la barra superior.
Finder enLaLista(Finder f) => find.descendant(of: find.byType(ListView), matching: f);

void main() {
  group('Crew List', () {
    testWidgets('muestra a cada persona con su departamento y su estado', (tester) async {
      // Arrange + Act
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(),
        prepararSesion: conRol(Roles.administrador),
      );

      // Assert
      expect(enLaLista(find.text('Ana')), findsOneWidget);
      expect(enLaLista(find.text('Arte')), findsOneWidget);
      expect(enLaLista(find.text('Activo')), findsOneWidget);
      expect(enLaLista(find.text('Luis')), findsOneWidget);
      expect(enLaLista(find.text('Sonido')), findsOneWidget);
      expect(enLaLista(find.text('Pendiente')), findsOneWidget);
      expect(find.textContaining('2 persona(s)'), findsOneWidget);
    });

    testWidgets('sin personas en el proyecto explica que está vacío', (tester) async {
      // Arrange + Act
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(usuarios: const []),
        prepararSesion: conRol(Roles.administrador),
      );

      // Assert: mensaje de vacío y ninguna fila ni paginación
      expect(find.text('Todavía no hay personas registradas en la plataforma.'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      expect(find.textContaining('persona(s)'), findsNothing);
    });

    testWidgets('si el backend rechaza la carga muestra su mensaje y "Reintentar" la recupera', (tester) async {
      // Arrange: primero el servidor niega el acceso; después responde bien
      var denegar = true;
      const mensaje = 'No tienes acceso a este módulo.';
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: (req) async {
          if (req.url.path.endsWith('/users/project/p1') && denegar) {
            return respuesta(null, success: false, message: mensaje, error: 'MODULE_ACCESS_DENIED', status: 403);
          }
          return apiCon()(req);
        },
        prepararSesion: conRol(Roles.administrador),
      );

      // Assert: se ve el motivo real y no hay lista
      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Ana'), findsNothing);

      // Act: el servidor se recupera y la persona toca Reintentar
      denegar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(mensaje), findsNothing);
      expect(enLaLista(find.text('Ana')), findsOneWidget);
    });

    testWidgets('el buscador filtra por nombre y avisa cuando no hay resultados', (tester) async {
      // Arrange
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(),
        prepararSesion: conRol(Roles.administrador),
      );

      // Act: escribe parte del nombre de Luis
      await tester.enterText(find.byType(TextField), 'lu');
      await tester.pumpAndSettle();

      // Assert: solo queda Luis
      expect(enLaLista(find.text('Luis')), findsOneWidget);
      expect(find.text('Ana'), findsNothing);

      // Act: un nombre que no existe
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sin resultados.'), findsOneWidget);
      expect(find.text('Luis'), findsNothing);
    });

    testWidgets('el filtro por departamento deja solo a las personas de ese departamento', (tester) async {
      // Arrange
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(),
        prepararSesion: conRol(Roles.administrador),
      );

      // Act: abre el desplegable (muestra "Todos") y elige Sonido
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sonido').last);
      await tester.pumpAndSettle();

      // Assert: solo Luis (Sonido); Ana (Arte) ya no aparece
      expect(enLaLista(find.text('Luis')), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
    });

    testWidgets('quien puede invitar ve "Agregar Persona"', (tester) async {
      // Arrange + Act
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(),
        prepararSesion: conRol(Roles.administrador),
      );

      // Assert
      expect(find.text('Agregar Persona'), findsOneWidget);
    });

    testWidgets('quien no puede invitar no ve "Agregar Persona" pero sí el directorio', (tester) async {
      // Arrange + Act
      await pumpWithProviders(
        tester,
        const CrewListScreen(),
        api: apiCon(),
        prepararSesion: conRol(Roles.usuario),
      );

      // Assert: sin botón, pero la lista se sigue viendo
      expect(find.text('Agregar Persona'), findsNothing);
      expect(enLaLista(find.text('Ana')), findsOneWidget);
    });
  });
}
