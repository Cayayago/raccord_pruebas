import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccord/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField muestra su etiqueta', (tester) async {
    // Arrange
    final ctrl = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AppTextField(label: 'E-mail', controller: ctrl)),
    ));
    // Act
    await tester.enterText(find.byType(TextFormField), 'a@b.co');
    // Assert
    expect(find.text('E-mail'), findsOneWidget);
    expect(ctrl.text, 'a@b.co');
  });
}
