// Capa Front — Carga masiva desde CSV/JSON (lib/core/bulk_import.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/bulk_import.dart';

void main() {
  group('parseBulkCsv', () {
    test('usa la primera fila como encabezado en minúsculas y sin espacios', () {
      // Arrange
      const csv = ' Nombre ,EDAD\nElena,30\nJulián,45';

      // Act
      final filas = parseBulkCsv(csv);

      // Assert
      expect(filas, [
        {'nombre': 'Elena', 'edad': '30'},
        {'nombre': 'Julián', 'edad': '45'},
      ]);
    });

    test('ignora filas completamente vacías', () {
      final filas = parseBulkCsv('nombre,edad\nElena,30\n,\n');

      expect(filas, hasLength(1));
    });

    test('rellena con vacío las columnas que faltan en una fila', () {
      final filas = parseBulkCsv('nombre,edad\nElena');

      expect(filas.single, {'nombre': 'Elena', 'edad': ''});
    });

    test('un archivo vacío no produce filas', () {
      expect(parseBulkCsv(''), isEmpty);
    });
  });

  group('parseBulkJson', () {
    test('convierte cada objeto en una fila con llaves normalizadas', () {
      final filas = parseBulkJson('[{"Nombre": "Elena", "Edad": 30, "Notas": null}]');

      expect(filas.single, {'nombre': 'Elena', 'edad': '30', 'notas': ''});
    });

    test('rechaza un JSON que no es una lista', () {
      expect(() => parseBulkJson('{"nombre": "Elena"}'), throwsException);
    });

    test('rechaza una lista con elementos que no son objetos', () {
      expect(() => parseBulkJson('["Elena"]'), throwsException);
    });
  });
}
