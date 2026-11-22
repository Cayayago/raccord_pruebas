// Capa Front — Invitaciones masivas (lib/core/invite_helpers.dart).
// Regla: cada fila del archivo se valida (columnas, área y rol
// existentes) y se informa el resultado fila por fila.
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/invite_helpers.dart';
import 'package:raccord/models/catalog.dart';

import '../helpers/fake_api.dart';

final departamentos = [Department(idDepartamento: 'd1', nombre: 'Vestuario', ubicacion: '')];
final roles = [RoleModel(idRol: 1004, nombre: 'Onset')];

Map<String, String> fila(String nombre, String correo, {String area = 'Vestuario', String rol = 'Onset'}) =>
    {'nombre completo': nombre, 'correo': correo, 'área': area, 'rol': rol};

void main() {
  test('invita las filas válidas y reporta las que el backend rechazó', () async {
    // Arrange
    final fake = FakeApi((_) async => sobre({
          'usuarios_creados': [
            {'mail': 'ana@b.co'},
          ],
          'errores': [
            {'mail': 'luis@b.co', 'error': 'El correo ya existe'},
          ],
        }));

    // Act
    final resultados = await bulkInvitePeople(
      api: fake.api,
      idProject: 'p1',
      idClient: 'c1',
      departamentos: departamentos,
      roles: roles,
      rows: [fila('Ana Ruiz', 'ANA@b.co'), fila('Luis Paz', 'luis@b.co')],
    );

    // Assert: la fila 1 del archivo es el encabezado, los datos empiezan en la 2
    expect(resultados.map((r) => (r.fila, r.ok)), [(2, true), (3, false)]);
    expect(resultados[1].detalle, 'El correo ya existe');
  });

  test('rechaza filas incompletas o con área/rol inexistentes sin llamar al backend', () async {
    final fake = FakeApi((_) async => sobre({}));

    final resultados = await bulkInvitePeople(
      api: fake.api,
      idProject: 'p1',
      idClient: 'c1',
      departamentos: departamentos,
      roles: roles,
      rows: [
        {'nombre': 'Sin correo'},
        fila('Ana', 'ana@b.co', area: 'Sonido'),
        fila('Ana', 'ana@b.co', rol: 'Productor'),
      ],
    );

    expect(resultados.every((r) => !r.ok), isTrue);
    expect(resultados[1].detalle, contains('"Sonido" no existe'));
    expect(resultados[2].detalle, contains('"Productor" no existe'));
    expect(fake.peticiones, isEmpty);
  });

  test('acepta área por id y rol sin importar mayúsculas', () async {
    final fake = FakeApi((_) async => sobre({
          'usuarios_creados': [
            {'mail': 'ana@b.co'},
          ],
        }));

    final resultados = await bulkInvitePeople(
      api: fake.api,
      idProject: 'p1',
      idClient: 'c1',
      departamentos: departamentos,
      roles: roles,
      rows: [fila('Ana', 'ana@b.co', area: 'd1', rol: 'ONSET')],
    );

    expect(resultados.single.ok, isTrue);
  });

  test('si el backend falla, todas las filas pendientes muestran el error', () async {
    final fake = FakeApi((_) async => sobre(null, success: false, message: 'Sin permisos'));

    final resultados = await bulkInvitePeople(
      api: fake.api,
      idProject: 'p1',
      idClient: 'c1',
      departamentos: departamentos,
      roles: roles,
      rows: [fila('Ana', 'ana@b.co'), fila('Luis', 'luis@b.co')],
    );

    expect(resultados.map((r) => r.detalle), ['Sin permisos', 'Sin permisos']);
  });
}
