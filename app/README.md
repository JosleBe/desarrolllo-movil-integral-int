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

### Contra el backend real
```bash
cd .. && docker compose up -d --build
flutter run -d chrome --web-port 8686 --dart-define-from-file=env/local.example.json
```
Con `USE_API=true` la autenticación usa `ApiAuthRepository` (Dio + JWT). El código de verificación de 6 dígitos llega a Mailpit (http://localhost:8025). Las demás épicas siguen con sus mocks.

### Modo demo (sin backend)
Sin `USE_API` (o con `USE_API=false`, como en `env/dev.example.json`) la app usa `MockAuthRepository` en memoria; así corren también las pruebas. Cuentas verificadas, iguales en el mock y en el backend: `demo@utez.edu.mx` / `demo1234` (todos los permisos), `laura@utez.edu.mx` / `laura1234`, `pedro@utez.edu.mx` / `pedro1234`. Con `ENV=dev` y el mock, la pantalla de verificación muestra y pre-rellena el código.

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
