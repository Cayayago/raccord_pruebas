import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raccord_frontend_flutter/ProfileScreen.dart';

void main() {
  testWidgets('ProfileScreen se construye sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica que el título del perfil aparezca en pantalla.
    expect(find.text('Perfil de Usuario'), findsOneWidget);
  });
}