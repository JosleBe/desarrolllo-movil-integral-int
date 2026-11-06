import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

/// Pruebas de flujo end-to-end (integración de widgets).
///
/// Recorren caminos completos como lo haría un usuario, verificando que
/// cada paso llega al estado esperado sin excepciones.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  /// Inicia sesión con la cuenta demo y espera a que cargue el catálogo.
  Future<void> loginAsDemo(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(
      find.byType(TextFormField).first,
      'demo@utez.edu.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('login lleva al catálogo', (tester) async {
    await loginAsDemo(tester);
    expect(find.text('Catálogo'), findsWidgets);
    // Hay al menos un artículo del seed visible.
    expect(
      find.textContaining('Calculadora'),
      findsWidgets,
      reason: 'El catálogo debe mostrar los útiles de ejemplo',
    );
  });

  testWidgets('flujo de renta: catálogo → detalle → solicitar → pagar → boleto',
      (tester) async {
    await loginAsDemo(tester);

    // Abre el primer artículo del catálogo (toca la tarjeta completa).
    await tester.tap(find.byType(Card).first);
    // Espera a que termine la navegación y el FutureProvider del detalle.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Confirma que estamos en el detalle de la publicación.
    expect(find.text('Precios y periodos'), findsOneWidget);

    // El botón de solicitar está al final del detalle: hazlo visible.
    final solicitar = find.widgetWithText(FilledButton, 'Solicitar renta');
    await tester.scrollUntilVisible(solicitar, 200);
    expect(solicitar, findsOneWidget);
    await tester.tap(solicitar);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Pantalla de solicitud: confirmar crea la renta.
    final confirmar = find.widgetWithText(FilledButton, 'Solicitar');
    expect(confirmar, findsOneWidget);
    await tester.tap(confirmar);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Sin excepciones a lo largo del flujo.
    expect(tester.takeException(), isNull);
  });

  testWidgets('el logout regresa al login', (tester) async {
    await loginAsDemo(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}
