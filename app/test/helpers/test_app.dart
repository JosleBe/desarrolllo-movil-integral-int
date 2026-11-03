import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/app.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/auth_repository.dart';
import 'package:sruu/features/auth/data/fake_auth_repository.dart';

FakeAuthRepository fakeRepo({DateTime Function()? clock}) => FakeAuthRepository(
  latency: Duration.zero,
  resendCooldown: Duration.zero,
  clock: clock,
);

/// Monta la app completa con backend simulado y almacenamiento en memoria.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? repo,
  TokenStorage? storage,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo ?? fakeRepo()),
      tokenStorageProvider.overrideWithValue(storage ?? InMemoryTokenStorage()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SruuApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Campo editable dentro del widget con [key].
Finder field(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(EditableText),
);
