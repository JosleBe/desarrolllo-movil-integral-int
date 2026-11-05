import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

void main() {
  setUp(() {
    // Sin token guardado: la app debe arrancar en login.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('arranca en la pantalla de login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    // Deja que _loadSession() resuelva (no hay sesión) y redibuje.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SRUU'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('rechaza correos que no son @utez.edu.mx', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.byType(TextFormField).first,
      'alguien@gmail.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'password1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Usa tu correo @utez.edu.mx'), findsOneWidget);
  });
}
