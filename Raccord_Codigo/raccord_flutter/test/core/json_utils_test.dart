import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/json_utils.dart';

void main() {
  group('pick', () {
    test('devuelve el valor de la primera llave presente y no nula', () {
      final json = {'a': null, 'b': 2, 'c': 3};
      expect(pick(json, ['a', 'b', 'c']), 2);
    });

    test('devuelve null si ninguna llave sirve', () {
      expect(pick({'a': null}, ['a', 'z']), isNull);
      expect(pick({}, ['a']), isNull);
    });

    test('un valor falsy pero no nulo (0, "", false) sí cuenta', () {
      expect(pick({'a': 0}, ['a']), 0);
      expect(pick({'a': ''}, ['a']), '');
      expect(pick({'a': false}, ['a']), false);
    });
  });

  group('asInt', () {
    test('convierte int, double y texto numérico', () {
      expect(asInt(5), 5);
      expect(asInt(5.9), 5);
      expect(asInt('42'), 42);
    });

    test('texto no numérico o nulo da null', () {
      expect(asInt('abc'), isNull);
      expect(asInt(null), isNull);
      expect(asInt(''), isNull);
    });
  });

  group('asBool', () {
    test('acepta true/false/1/0 sin importar mayúsculas', () {
      expect(asBool(true), isTrue);
      expect(asBool('TRUE'), isTrue);
      expect(asBool('1'), isTrue);
      expect(asBool('False'), isFalse);
      expect(asBool('0'), isFalse);
    });

    test('valores ambiguos dan null (no se adivina)', () {
      expect(asBool('si'), isNull);
      expect(asBool('2'), isNull);
      expect(asBool(null), isNull);
    });
  });

  group('asString / asListOfMap', () {
    test('asString convierte cualquier cosa y respeta null', () {
      expect(asString(10), '10');
      expect(asString(null), isNull);
    });

    test('asListOfMap ignora elementos que no son mapas', () {
      final r = asListOfMap([
        {'a': 1},
        'basura',
        3,
        {'b': 2},
      ]);
      expect(r, [
        {'a': 1},
        {'b': 2},
      ]);
    });

    test('asListOfMap con algo que no es lista devuelve lista vacía', () {
      expect(asListOfMap(null), isEmpty);
      expect(asListOfMap({'a': 1}), isEmpty);
    });
  });
}
