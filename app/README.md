# SRUU — App móvil (Flutter)

Sistema de Renta de Útiles Universitarios (UTEZ). Historias de usuario en [`../hu`](../hu/README.md).

## Requisitos
- Flutter 3.44+ / Dart 3.12+ (`flutter doctor`)

## Arranque
```bash
flutter pub get
cp env/dev.example.json env/dev.json   # ajusta API_BASE_URL
flutter run --dart-define-from-file=env/dev.json
```
> En el emulador de Android, `10.0.2.2` apunta al `localhost` de tu máquina.

### Modo demo (sin backend)
La autenticación usa hoy `MockAuthRepository` (en memoria). Cuentas verificadas: `demo@utez.edu.mx` / `demo1234` (todos los permisos), `laura@utez.edu.mx` / `laura1234`, `pedro@utez.edu.mx` / `pedro1234`. Con `ENV=dev`, la pantalla de verificación muestra y pre-rellena el código. Para conectar el backend basta cambiar `authRepositoryProvider` en `features/auth/presentation/providers/auth_controller.dart`.

## Autenticación (Épica 1)
| HU | Pantalla | Archivo |
|---|---|---|
| HU-01 Registro | Crear cuenta | `register_page.dart` |
| HU-02 Verificación | Verifica tu correo (código + reenvío) | `verify_email_page.dart` |
| HU-03 Sesión | Iniciar sesión / cerrar sesión | `login_page.dart`, `AuthController.logout` |
| HU-04 Perfil | Mi perfil, permisos e historial | `profile_page.dart` |

Contrato con el backend: [`docs/auth-api.md`](docs/auth-api.md).

## Comandos
| Tarea | Comando |
|---|---|
| Analizar | `flutter analyze` |
| Formatear | `dart format lib test` |
| Pruebas | `flutter test` |
| Build web (PWA) | `flutter build web --dart-define-from-file=env/prod.json` |

## Estructura
Arquitectura feature-first (domain / data / presentation); detalle en `ARQUITECTURA.md`.
```
lib/
├── main.dart              # ProviderScope + runApp
├── app.dart               # MaterialApp.router, temas
├── core/
│   ├── config/env.dart    # Variables por ambiente (--dart-define)
│   ├── network/           # Dio + interceptor JWT
│   ├── router/            # go_router y rutas
│   ├── storage/           # flutter_secure_storage (JWT)
│   ├── theme/             # Tema Material 3 (verde UTEZ)
│   └── widgets/           # Widgets compartidos (PressableScale)
└── features/<feature>/
    ├── domain/            # modelos, contratos y excepciones
    ├── data/              # implementaciones (mock hoy, API mañana)
    └── presentation/      # páginas, widgets y providers (Riverpod)
```

## Stack
Riverpod (estado/DI) · go_router (navegación) · Dio (HTTP) · flutter_secure_storage (JWT) · qr_flutter (QR)
