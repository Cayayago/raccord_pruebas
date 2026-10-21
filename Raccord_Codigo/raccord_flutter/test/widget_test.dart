// Reemplaza la plantilla por defecto de `flutter create` (probaba un
// contador `MyApp` que no existe en Raccord y rompía `flutter test`).
// Las pruebas unitarias reales viven en test/core/.
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/permissions.dart';

void main() {
  test('el catálogo de roles tiene los cinco ids acordados', () {
    expect(
      [Roles.administrador, Roles.director, Roles.jefeDepartamento, Roles.onset, Roles.usuario],
      [1001, 1002, 1003, 1004, 1005],
    );
  });
}
