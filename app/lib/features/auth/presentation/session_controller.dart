import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validators.dart';

/// Reloj inyectable para poder probar la expiración del JWT.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

sealed class SessionState {
  const SessionState();
}

/// Arranque: se está leyendo/validando la sesión guardada.
final class SessionRestoring extends SessionState {
  const SessionRestoring();
}

final class SignedOut extends SessionState {
  const SignedOut({this.reason});
  final SignOutReason? reason;
}

enum SignOutReason { expired, userRequested }

final class SignedIn extends SessionState {
  const SignedIn({required this.user, required this.expiresAt});
  final AuthUser user;
  final DateTime expiresAt;
}

/// Dueño de la sesión (HU-03): inicia, restaura, expira y cierra sesión.
class SessionController extends Notifier<SessionState> {
  Timer? _expiryTimer;
  StreamSubscription<void>? _unauthorizedSub;

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  SessionState build() {
    _unauthorizedSub = ref
        .watch(unauthorizedEventsProvider)
        .stream
        .listen((_) => _endLocally(SignOutReason.expired));
    ref.onDispose(() {
      _expiryTimer?.cancel();
      _unauthorizedSub?.cancel();
    });
    Future.microtask(_restore);
    return const SessionRestoring();
  }

  Future<void> _restore() async {
    final stored = await _storage.read();
    if (!ref.mounted) return;
    if (stored == null) {
      state = const SignedOut();
      return;
    }
    if (stored.isExpiredAt(_now())) {
      await _storage.clear();
      if (ref.mounted) state = const SignedOut(reason: SignOutReason.expired);
      return;
    }
    try {
      // Confirma con el servidor que el token sigue vigente (no revocado).
      final user = await _repo.currentUser(stored.accessToken);
      if (!ref.mounted) return;
      _enter(user, stored.expiresAt);
    } on AuthFailure catch (failure) {
      if (failure is! NetworkFailure) await _storage.clear();
      if (ref.mounted) {
        state = SignedOut(
          reason: failure is SessionExpired ? SignOutReason.expired : null,
        );
      }
    }
  }

  /// Lanza [AuthFailure] si falla; la UI decide el mensaje.
  Future<void> signIn({required String email, required String password}) async {
    final session = await _repo.login(
      email: AuthValidators.normalizeEmail(email),
      password: password,
    );
    await _storage.save(
      StoredSession(
        accessToken: session.accessToken,
        expiresAt: session.expiresAt,
      ),
    );
    if (!ref.mounted) return;
    _enter(session.user, session.expiresAt);
  }

  /// Invalida el token en el servidor y borra la sesión local. Si el
  /// servidor no responde, la sesión local se borra de todos modos.
  Future<void> signOut() async {
    final token = await _storage.readAccessToken();
    if (token != null) {
      try {
        await _repo.logout(token);
      } on AuthFailure {
        // El token expira por sí solo; lo importante es no conservarlo.
      }
    }
    await _endLocally(SignOutReason.userRequested);
  }

  void _enter(AuthUser user, DateTime expiresAt) {
    _expiryTimer?.cancel();
    final remaining = expiresAt.difference(_now());
    if (remaining <= Duration.zero) {
      _endLocally(SignOutReason.expired);
      return;
    }
    _expiryTimer = Timer(remaining, () => _endLocally(SignOutReason.expired));
    state = SignedIn(user: user, expiresAt: expiresAt);
  }

  Future<void> _endLocally(SignOutReason reason) async {
    _expiryTimer?.cancel();
    await _storage.clear();
    if (ref.mounted) state = SignedOut(reason: reason);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
