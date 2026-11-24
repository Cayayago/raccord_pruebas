// Capa Front — diálogo "Invitar persona" (lib/widgets/invite_person_dialog.dart).
// Se monta con pumpWithProviders (helper de la semana 3): el backend es un
// MockClient y se verifica qué envía el diálogo y qué ve la persona.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:raccord/models/catalog.dart';
import 'package:raccord/widgets/invite_person_dialog.dart';

import '../helpers/pump_with_providers.dart';

final _departamentos = [Department(idDepartamento: 'd1', nombre: 'Arte', ubicacion: 'Set A')];
final _roles = [RoleModel(idRol: 1004, nombre: 'Jefe de Departamento')];

/// Pantalla mínima con un botón que abre el diálogo y muestra lo que devolvió.
class _Anfitrion extends StatefulWidget {
  const _Anfitrion();

  @override
  State<_Anfitrion> createState() => _AnfitrionState();
}

class _AnfitrionState extends State<_Anfitrion> {
  String _resultado = 'sin abrir';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ElevatedButton(
          onPressed: () async {
            final r = await showDialog<bool>(
              context: context,
              builder: (_) => InvitePersonDialog(
                projectId: 'p1',
                idClient: 'c1',
                departamentos: _departamentos,
                roles: _roles,
              ),
            );
            setState(() => _resultado = 'resultado: $r');
          },
          child: const Text('Abrir'),
        ),
        Text(_resultado),
      ]),
    );
  }
}

Future<void> _abrir(WidgetTester tester, {Future<http.Response> Function(http.Request)? api, List<http.Request>? peticiones}) async {
  await pumpWithProviders(tester, const _Anfitrion(), api: api, peticiones: peticiones);
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  expect(find.text('Invitar al equipo'), findsOneWidget);
}

Future<void> _llenar(WidgetTester tester) async {
  await tester.enterText(campo('Nombre completo'), 'Ana Ruiz');
  await tester.enterText(campo('Correo electrónico'), 'ana@b.co');
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Arte').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Jefe de Departamento').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin llenar nada explica qué falta y no llama al backend', (tester) async {
    final peticiones = <http.Request>[];
    await _abrir(tester, peticiones: peticiones);

    await tester.tap(find.text('Enviar invitación'));
    await tester.pump();

    expect(find.text('Completa nombre, correo, área y rol'), findsOneWidget);
    expect(peticiones, isEmpty);
  });

  testWidgets('con todo lleno envía la invitación y se cierra con true', (tester) async {
    final peticiones = <http.Request>[];
    await _abrir(tester, peticiones: peticiones, api: (_) async => respuesta({'usuarios_creados': [], 'errores': []}));

    await _llenar(tester);
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();

    expect(peticiones.single.url.path, '/users/invite');
    final cuerpo = jsonDecode(peticiones.single.body) as Map;
    expect(cuerpo['id_project'], 'p1');
    expect(cuerpo['invitados'], [
      {'nombre_completo': 'Ana Ruiz', 'mail': 'ana@b.co', 'id_departamento': 'd1', 'id_rol': 1004},
    ]);
    expect(find.text('Invitar al equipo'), findsNothing);
    expect(find.text('resultado: true'), findsOneWidget);
  });

  testWidgets('si el backend rechaza, muestra su mensaje y el diálogo sigue abierto', (tester) async {
    await _abrir(tester,
        api: (_) async => respuesta(null, success: false, message: 'Ese correo ya está en el proyecto', error: 'DUPLICATE'));

    await _llenar(tester);
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();

    expect(find.text('Ese correo ya está en el proyecto'), findsOneWidget);
    expect(find.text('Invitar al equipo'), findsOneWidget);
  });

  testWidgets('Cancelar cierra sin invitar (false)', (tester) async {
    final peticiones = <http.Request>[];
    await _abrir(tester, peticiones: peticiones);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('resultado: false'), findsOneWidget);
    expect(peticiones, isEmpty);
  });
}
