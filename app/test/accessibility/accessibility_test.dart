import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';

/// Auditoría de accesibilidad con los matchers oficiales de Flutter.
///
/// Verifican de forma objetiva:
/// - Tamaño mínimo de los objetivos de toque (48x48 Android / 44x44 iOS).
/// - Contraste de texto suficiente (WCAG AA).
/// - Que los controles tappables tengan una etiqueta semántica (para
///   lectores de pantalla como TalkBack / VoiceOver).
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SruuApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> pumpCatalog(WidgetTester tester) async {
    await pumpLogin(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'demo@utez.edu.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'demo1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  group('accesibilidad — pantalla de login', () {
    testWidgets('cumple tap targets de Android', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLogin(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cumple tap targets de iOS', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLogin(tester);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cumple contraste de texto (WCAG)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLogin(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('los controles tappables tienen etiqueta', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLogin(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('accesibilidad — catálogo', () {
    testWidgets('cumple tap targets de Android', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCatalog(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cumple contraste de texto (WCAG)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCatalog(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('accesibilidad — perfil', () {
    testWidgets('tap targets y etiquetas en el perfil', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCatalog(tester);
      // Abre el perfil desde el ícono del AppBar.
      await tester.tap(find.byTooltip('Mi perfil'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
