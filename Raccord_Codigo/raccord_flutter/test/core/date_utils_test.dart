import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/core/date_utils.dart';

void main() {
  group('formatDateEs', () {
    test('formatea día, mes abreviado en español y año', () {
      expect(formatDateEs(DateTime(2026, 10, 20)), '20 oct 2026');
    });

    // Valores límite del arreglo de meses: enero (índice 0) y diciembre (11).
    test('primer y último mes del año', () {
      expect(formatDateEs(DateTime(2026, 1, 5)), '5 ene 2026');
      expect(formatDateEs(DateTime(2026, 12, 31)), '31 dic 2026');
    });
  });

  group('formatTimeOfDay', () {
    test('recorta los segundos de HH:MM:SS', () {
      expect(formatTimeOfDay('07:30:00'), '07:30');
    });

    test('nulo o vacío da cadena vacía', () {
      expect(formatTimeOfDay(null), '');
      expect(formatTimeOfDay(''), '');
    });

    test('un valor sin ":" se devuelve tal cual', () {
      expect(formatTimeOfDay('7'), '7');
    });

    test('HH:MM ya recortado se conserva', () {
      expect(formatTimeOfDay('07:30'), '07:30');
    });
  });
}
