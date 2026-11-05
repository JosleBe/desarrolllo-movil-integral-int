import '../../../core/storage/token_storage.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import '../domain/user_permissions.dart';

/// Registro interno de una cuenta en el mock (incluye datos que el dominio
/// no expone, como la contraseña y el token de verificación pendiente).
class _Account {
  _Account({
    required this.user,
    required this.password,
    this.pendingToken,
  });

  User user;
  String password;
  String? pendingToken;
}

/// Implementación en memoria de [AuthRepository] para trabajar sin backend.
///
/// Simula registro, verificación por token, login/logout y edición de
/// perfil. El "JWT" es un token ficticio que se guarda en [TokenStorage],
/// igual que haría la implementación real, de modo que el resto de la app
/// no note la diferencia cuando se conecte la API.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._tokenStorage) {
    // Cuenta de demostración ya verificada, para entrar directo en pruebas.
    // Credenciales: demo@utez.edu.mx / demo1234
    const demo = User(
      id: 'u-demo',
      email: 'demo@utez.edu.mx',
      fullName: 'Usuario Demo',
      phone: '7771234567',
      status: AccountStatus.verified,
      permissions: UserPermissions(
        renter: true,
        seller: true,
        reception: true,
        admin: true,
      ),
    );
    _accounts[demo.email] = _Account(user: demo, password: 'demo1234');

    // Cuentas de ejemplo para el panel de administración (HU-24/25).
    const laura = User(
      id: 'u-laura',
      email: 'laura@utez.edu.mx',
      fullName: 'Laura M.',
      status: AccountStatus.verified,
      permissions: UserPermissions(renter: true, seller: true),
    );
    const pedro = User(
      id: 'u-pedro',
      email: 'pedro@utez.edu.mx',
      fullName: 'Pedro S.',
      status: AccountStatus.verified,
      permissions: UserPermissions(seller: true),
    );
    _accounts[laura.email] = _Account(user: laura, password: 'laura1234');
    _accounts[pedro.email] = _Account(user: pedro, password: 'pedro1234');
  }

  static const _domain = '@utez.edu.mx';
  static const _networkDelay = Duration(milliseconds: 400);

  final TokenStorage _tokenStorage;
  final Map<String, _Account> _accounts = {};

  /// Correo del usuario con sesión activa en el mock (espejo del token).
  String? _sessionEmail;
  int _idCounter = 0;

  bool _isInstitutional(String email) =>
      email.toLowerCase().endsWith(_domain);

  String _normalize(String email) => email.trim().toLowerCase();

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_networkDelay);
    final normalized = _normalize(email);

    if (!_isInstitutional(normalized)) {
      throw const InvalidInstitutionalEmail();
    }
    if (_accounts.containsKey(normalized)) {
      throw const EmailAlreadyRegistered();
    }

    final token = _generateToken();
    final user = User(
      id: 'u-${_idCounter++}',
      email: normalized,
      fullName: fullName.trim(),
    );
    _accounts[normalized] = _Account(
      user: user,
      password: password,
      pendingToken: token,
    );

    return RegistrationResult(user: user, devToken: token);
  }

  @override
  Future<User> verifyEmail({
    required String email,
    required String token,
  }) async {
    await Future<void>.delayed(_networkDelay);
    final account = _accounts[_normalize(email)];

    if (account == null ||
        account.pendingToken == null ||
        account.pendingToken != token.trim()) {
      throw const InvalidVerificationToken();
    }

    account.user = account.user.copyWith(status: AccountStatus.verified);
    account.pendingToken = null;
    return account.user;
  }

  @override
  Future<String> resendVerificationToken({required String email}) async {
    await Future<void>.delayed(_networkDelay);
    final account = _accounts[_normalize(email)];

    if (account == null) {
      throw const InvalidCredentials();
    }
    if (account.user.isVerified) {
      throw const AccountNotVerified();
    }

    final token = _generateToken();
    account.pendingToken = token;
    return token;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_networkDelay);
    final account = _accounts[_normalize(email)];

    if (account == null || account.password != password) {
      throw const InvalidCredentials();
    }
    if (!account.user.isVerified) {
      throw const AccountNotVerified();
    }

    await _tokenStorage.saveAccessToken(_fakeJwtFor(account.user));
    _sessionEmail = account.user.email;
    return account.user;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(_networkDelay);
    await _tokenStorage.clear();
    _sessionEmail = null;
  }

  @override
  Future<User?> currentUser() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      _sessionEmail = null;
      return null;
    }
    final email = _sessionEmail;
    if (email == null) {
      return null;
    }
    return _accounts[email]?.user;
  }

  @override
  Future<User> updateProfile({String? fullName, String? phone}) async {
    await Future<void>.delayed(_networkDelay);
    final email = _sessionEmail;
    final account = email == null ? null : _accounts[email];

    if (account == null) {
      throw const InvalidCredentials();
    }

    account.user = account.user.copyWith(
      fullName: fullName?.trim(),
      phone: phone?.trim(),
    );
    return account.user;
  }

  @override
  Future<List<User>> listUsers() async {
    await Future<void>.delayed(_networkDelay);
    return _accounts.values.map((a) => a.user).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  @override
  Future<User> setPermission({
    required String userId,
    required ManagedPermission permission,
    required bool active,
  }) async {
    await Future<void>.delayed(_networkDelay);
    final account = _accounts.values.firstWhere(
      (a) => a.user.id == userId,
      orElse: () => throw const InvalidCredentials(),
    );
    // Cambia solo el permiso indicado, sin tocar el otro (RN-02).
    final current = account.user.permissions;
    final updated = switch (permission) {
      ManagedPermission.renter => current.copyWith(renter: active),
      ManagedPermission.seller => current.copyWith(seller: active),
    };
    account.user = account.user.copyWith(permissions: updated);
    return account.user;
  }

  String _generateToken() =>
      (100000 + DateTime.now().microsecondsSinceEpoch % 900000).toString();

  String _fakeJwtFor(User user) =>
      'mock.${user.id}.${DateTime.now().millisecondsSinceEpoch}';
}
