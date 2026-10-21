import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

void main() {
  testWidgets('arranca en la pantalla de login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pumpAndSettle();

    expect(find.text('SRUU'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('rechaza correos que no son @utez.edu.mx', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'alguien@gmail.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Usa tu correo @utez.edu.mx'), findsOneWidget);
  });
}
