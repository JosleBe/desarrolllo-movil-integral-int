import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

/// Pruebas de adaptación en una pantalla de celular pequeño.
///
/// Flutter lanza una excepción de "RenderFlex overflowed" cuando algo se
/// desborda; estas pruebas fallarían si alguna de las pantallas recorridas
/// no cupiera en 360x690 (un tamaño de móvil angosto típico).
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('login y catálogo no desbordan en pantalla pequeña', (
    tester,
  ) async {
    // Simula un celular angosto.
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Inicia sesión con la cuenta demo (todos los roles).
    await tester.enterText(
      find.byType(TextFormField).first,
      'demo@utez.edu.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    // Espera a que el mock resuelva el login y cargue el catálogo.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Si algo se hubiera desbordado, el test ya habría fallado con una
    // excepción de overflow capturada por el framework.
    expect(tester.takeException(), isNull);
  });

  testWidgets('recorre las secciones del shell sin desbordar', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Recorre cada destino de la barra de navegación inferior.
    final destinations = find.byType(NavigationDestination);
    final count = tester.widgetList(destinations).length;
    for (var i = 0; i < count; i++) {
      await tester.tap(destinations.at(i));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow al abrir la sección índice $i',
      );
    }
  });
}
