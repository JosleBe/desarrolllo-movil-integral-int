import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sesión persistida: el JWT y el instante en que expira.
class StoredSession {
  const StoredSession({required this.accessToken, required this.expiresAt});

  final String accessToken;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// Guarda el JWT de sesión. La contraseña nunca se persiste en el dispositivo.
abstract class TokenStorage {
  Future<StoredSession?> read();
  Future<String?> readAccessToken();
  Future<void> save(StoredSession session);
  Future<void> clear();
}

/// Implementación en Keychain (iOS) / Keystore (Android) / WebCrypto (Web).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _expiresAtKey = 'access_token_expires_at';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<StoredSession?> read() async {
    final token = await _storage.read(key: _accessTokenKey);
    final expiresAt = DateTime.tryParse(
      await _storage.read(key: _expiresAtKey) ?? '',
    );
    if (token == null || expiresAt == null) return null;
    return StoredSession(accessToken: token, expiresAt: expiresAt);
  }

  @override
  Future<void> save(StoredSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(
      key: _expiresAtKey,
      value: session.expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

/// Implementación volátil para pruebas.
class InMemoryTokenStorage implements TokenStorage {
  StoredSession? _session;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<String?> readAccessToken() async => _session?.accessToken;

  @override
  Future<void> save(StoredSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);
