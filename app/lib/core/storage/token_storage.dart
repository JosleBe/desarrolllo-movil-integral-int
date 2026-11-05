import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el JWT de sesión en almacenamiento seguro (Keychain / Keystore).
class TokenStorage {
  TokenStorage(this._storage);

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
