import 'dart:math';

import '../domain/auth_models.dart';
import '../domain/auth_validators.dart';
import 'auth_repository.dart';

/// Correo que el backend simulado "envía". Se muestra en la app en modo demo
/// para poder abrir el enlace de verificación sin un servidor de correo.
class DemoEmail {
  const DemoEmail({
    required this.to,
    required this.token,
    required this.sentAt,
  });
  final String to;
  final String token;
  final DateTime sentAt;
}

/// Backend en memoria que reproduce las reglas del servidor real: dominio
/// institucional, correo único, tokens de verificación con vigencia y un solo
/// uso, JWT con expiración y revocación al cerrar sesión.
///
/// Solo para desarrollo y pruebas. En producción el hash de contraseña
/// (BCrypt/Argon2) y la emisión del JWT ocurren en el backend.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 450),
    this.verificationTtl = const Duration(hours: 24),
    this.sessionTtl = const Duration(hours: 8),
    this.resendCooldown = const Duration(seconds: 60),
    bool seedDemoUser = true,
  }) : _clock = clock ?? DateTime.now {
    if (seedDemoUser) {
      _users['demo@utez.edu.mx'] = _FakeUser(
        id: 'u-demo',
        fullName: 'Ana Demo Ramírez',
        email: 'demo@utez.edu.mx',
        password: 'Demo1234',
        status: AccountStatus.verified,
        role: UserRole.base,
      );
    }
  }

  final DateTime Function() _clock;
  final Duration latency;
  final Duration verificationTtl;
  final Duration sessionTtl;
  final Duration resendCooldown;

  final _users = <String, _FakeUser>{};
  final _verificationTokens = <String, _VerificationToken>{};
  final _sessions = <String, _FakeSession>{};
  final _random = Random.secure();
  final List<DemoEmail> outbox = [];

  DemoEmail? lastEmailTo(String email) {
    final normalized = AuthValidators.normalizeEmail(email);
    for (final mail in outbox.reversed) {
      if (mail.to == normalized) return mail;
    }
    return null;
  }

  /// Solo demo: hace que los tokens vigentes de [email] venzan ya.
  void debugExpireVerificationTokens(String email) {
    final normalized = AuthValidators.normalizeEmail(email);
    for (final t in _verificationTokens.values) {
      if (t.email == normalized) t.expiresAt = _clock();
    }
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _delay();
    final normalized = AuthValidators.normalizeEmail(email);
    if (!AuthValidators.isInstitutionalEmail(normalized)) {
      throw const InstitutionalEmailRequired();
    }
    if (_users.containsKey(normalized)) throw const EmailAlreadyRegistered();

    final user = _FakeUser(
      id: 'u-${_users.length + 1}',
      fullName: fullName.trim(),
      email: normalized,
      password: password,
      status: AccountStatus.pendingVerification,
      role: UserRole.none,
    );
    _users[normalized] = user;
    _sendVerification(normalized);
    return user.toAuthUser();
  }

  @override
  Future<AuthUser> verifyEmail(String token) async {
    await _delay();
    final record = _verificationTokens[token];
    if (record == null) throw const VerificationTokenInvalid();
    if (record.usedAt != null || record.revoked) {
      throw VerificationTokenAlreadyUsed(email: record.email);
    }
    if (!_clock().isBefore(record.expiresAt)) {
      throw VerificationTokenExpired(email: record.email);
    }
    record.usedAt = _clock();
    final user = _users[record.email]!
      ..status = AccountStatus.verified
      ..role = UserRole.base;
    return user.toAuthUser();
  }

  @override
  Future<void> resendVerification(String email) async {
    await _delay();
    final normalized = AuthValidators.normalizeEmail(email);
    final user = _users[normalized];
    // Respuesta idéntica exista o no la cuenta (no enumerar correos).
    if (user == null || user.status == AccountStatus.verified) return;
    final last = lastEmailTo(normalized);
    if (last != null && _clock().difference(last.sentAt) < resendCooldown) {
      throw const TooManyRequests();
    }
    for (final t in _verificationTokens.values) {
      if (t.email == normalized && t.usedAt == null) t.revoked = true;
    }
    _sendVerification(normalized);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await _delay();
    final user = _users[AuthValidators.normalizeEmail(email)];
    if (user == null || user.password != password) {
      throw const InvalidCredentials();
    }
    if (user.status != AccountStatus.verified) {
      throw EmailNotVerified(user.email);
    }
    final token = 'fake.${_randomToken()}';
    final expiresAt = _clock().add(sessionTtl);
    _sessions[token] = _FakeSession(user.email, expiresAt);
    return AuthSession(
      accessToken: token,
      expiresAt: expiresAt,
      user: user.toAuthUser(),
    );
  }

  @override
  Future<void> logout(String accessToken) async {
    await _delay();
    _sessions[accessToken]?.revoked = true;
  }

  @override
  Future<AuthUser> currentUser(String accessToken) async {
    await _delay();
    final session = _sessions[accessToken];
    if (session == null ||
        session.revoked ||
        !_clock().isBefore(session.expiresAt)) {
      throw const SessionExpired();
    }
    return _users[session.email]!.toAuthUser();
  }

  void _sendVerification(String email) {
    final token = _randomToken();
    _verificationTokens[token] = _VerificationToken(
      email,
      _clock().add(verificationTtl),
    );
    outbox.add(DemoEmail(to: email, token: token, sentAt: _clock()));
  }

  String _randomToken() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      32,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> _delay() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);
}

class _FakeUser {
  _FakeUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.status,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String password;
  AccountStatus status;
  UserRole role;

  AuthUser toAuthUser() => AuthUser(
    id: id,
    email: email,
    fullName: fullName,
    status: status,
    role: role,
  );
}

class _VerificationToken {
  _VerificationToken(this.email, this.expiresAt);
  final String email;
  DateTime expiresAt;
  DateTime? usedAt;
  bool revoked = false;
}

class _FakeSession {
  _FakeSession(this.email, this.expiresAt);
  final String email;
  final DateTime expiresAt;
  bool revoked = false;
}
