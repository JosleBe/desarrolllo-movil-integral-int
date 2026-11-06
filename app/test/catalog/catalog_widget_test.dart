import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/features/catalog/presentation/catalog_page.dart';
import 'package:sruu/features/catalog/presentation/my_listings_page.dart';

void main() {
  testWidgets('CatalogPage renderiza buscador e items', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CatalogPage()),
        ),
      ),
    );

    // Esperar a que el FutureProvider del mock cargue los datos
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar útiles...'), findsOneWidget);
  });

  testWidgets('MyListingsPage renderiza boton de publicar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MyListingsPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Publicar'), findsOneWidget);
  });
}
