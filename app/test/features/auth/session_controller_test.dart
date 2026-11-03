import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sruu/core/storage/token_storage.dart';
import 'package:sruu/features/auth/data/auth_repository.dart';
import 'package:sruu/features/auth/data/fake_auth_repository.dart';
import 'package:sruu/features/auth/domain/auth_models.dart';
import 'package:sruu/features/auth/presentation/session_controller.dart';

void main() {
  late InMemoryTokenStorage storage;

  ProviderContainer build(FakeAuthRepository repo) {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() => storage = InMemoryTokenStorage());

  test('sin sesión guardada arranca en SignedOut', () async {
    final c = build(FakeAuthRepository(latency: Duration.zero));
    expect(c.read(sessionControllerProvider), isA<SessionRestoring>());
    await settle();
    expect(c.read(sessionControllerProvider), isA<SignedOut>());
  });

  test('iniciar sesión guarda el JWT y su expiración', () async {
    final c = build(FakeAuthRepository(latency: Duration.zero));
    await settle();
    await c
        .read(sessionControllerProvider.notifier)
        .signIn(email: 'demo@utez.edu.mx', password: 'Demo1234');
    expect(c.read(sessionControllerProvider), isA<SignedIn>());
    final stored = await storage.read();
    expect(stored, isNotNull);
    expect(stored!.expiresAt.isAfter(DateTime.now()), isTrue);
  });

  test('credenciales incorrectas no guardan nada', () async {
    final c = build(FakeAuthRepository(latency: Duration.zero));
    await settle();
    await expectLater(
      c
          .read(sessionControllerProvider.notifier)
          .signIn(email: 'demo@utez.edu.mx', password: 'mala'),
      throwsA(isA<InvalidCredentials>()),
    );
    expect(await storage.read(), isNull);
    expect(c.read(sessionControllerProvider), isA<SignedOut>());
  });

  test(
    'cerrar sesión revoca el token en el servidor y borra el local',
    () async {
      final repo = FakeAuthRepository(latency: Duration.zero);
      final c = build(repo);
      await settle();
      await c
          .read(sessionControllerProvider.notifier)
          .signIn(email: 'demo@utez.edu.mx', password: 'Demo1234');
      final token = (await storage.read())!.accessToken;

      await c.read(sessionControllerProvider.notifier).signOut();

      expect(await storage.read(), isNull);
      expect(c.read(sessionControllerProvider), isA<SignedOut>());
      expect(repo.currentUser(token), throwsA(isA<SessionExpired>()));
    },
  );

  test('la sesión se cierra sola al expirar el JWT', () async {
    final c = build(
      FakeAuthRepository(
        latency: Duration.zero,
        sessionTtl: const Duration(milliseconds: 150),
      ),
    );
    await settle();
    await c
        .read(sessionControllerProvider.notifier)
        .signIn(email: 'demo@utez.edu.mx', password: 'Demo1234');
    expect(c.read(sessionControllerProvider), isA<SignedIn>());

    await Future<void>.delayed(const Duration(milliseconds: 250));

    final state = c.read(sessionControllerProvider);
    expect(
      state,
      isA<SignedOut>().having((s) => s.reason, 'reason', SignOutReason.expired),
    );
    expect(await storage.read(), isNull);
  });

  test('al arrancar descarta un token revocado en el servidor', () async {
    final repo = FakeAuthRepository(latency: Duration.zero);
    final session = await repo.login(
      email: 'demo@utez.edu.mx',
      password: 'Demo1234',
    );
    await repo.logout(session.accessToken);
    await storage.save(
      StoredSession(
        accessToken: session.accessToken,
        expiresAt: session.expiresAt,
      ),
    );

    final c = build(repo);
    c.read(sessionControllerProvider); // construye el controlador
    await settle();
    await settle();

    expect(c.read(sessionControllerProvider), isA<SignedOut>());
    expect(await storage.read(), isNull);
  });

  test('al arrancar restaura una sesión vigente', () async {
    final repo = FakeAuthRepository(latency: Duration.zero);
    final session = await repo.login(
      email: 'demo@utez.edu.mx',
      password: 'Demo1234',
    );
    await storage.save(
      StoredSession(
        accessToken: session.accessToken,
        expiresAt: session.expiresAt,
      ),
    );

    final c = build(repo);
    c.read(sessionControllerProvider); // construye el controlador
    await settle();
    await settle();

    expect(c.read(sessionControllerProvider), isA<SignedIn>());
  });
}
