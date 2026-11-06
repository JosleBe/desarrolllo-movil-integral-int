import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

/// Prueba de humo de navegación: abre todas las secciones y subpantallas
/// clave con la cuenta demo (que tiene todos los roles) y verifica que
/// ninguna ruta lanza excepción al construirse.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  Future<void> loginAsDemo(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.enterText(
      find.byType(TextFormField).first,
      'demo@utez.edu.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('abre el perfil desde el AppBar', (tester) async {
    await loginAsDemo(tester);
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Mi perfil'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre todas las secciones del menú inferior', (tester) async {
    await loginAsDemo(tester);
    final destinations = find.byType(NavigationDestination);
    final count = tester.widgetList(destinations).length;
    // demo tiene permisos de Rentador, Vendedor y Admin:
    // Catálogo + Pedidos + Publicar + Rentas + Admin = 5 secciones.
    expect(count, 5);
    for (var i = 0; i < count; i++) {
      await tester.tap(destinations.at(i));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Falló al abrir la sección índice $i',
      );
    }
  });

  // Cada subpantalla del panel Admin se abre en su propio test para evitar
  // interferencia de timing entre transiciones.
  Future<void> abreSubpantallaAdmin(WidgetTester tester, String opcion) async {
    await loginAsDemo(tester);
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text(opcion));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: 'Falló al abrir "$opcion"');
  }

  testWidgets('Admin: abre Incidencias', (tester) async {
    await abreSubpantallaAdmin(tester, 'Incidencias');
  });

  testWidgets('Admin: abre Usuarios y permisos', (tester) async {
    await abreSubpantallaAdmin(tester, 'Usuarios y permisos');
  });

  testWidgets('Admin: abre Bitácora de auditoría', (tester) async {
    await abreSubpantallaAdmin(tester, 'Bitácora de auditoría');
  });

  testWidgets('Admin: abre Moderar catálogo', (tester) async {
    await abreSubpantallaAdmin(tester, 'Moderar catálogo');
  });
}
