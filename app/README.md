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

## Comandos
| Tarea | Comando |
|---|---|
| Analizar | `flutter analyze` |
| Formatear | `dart format lib test` |
| Pruebas | `flutter test` |
| Build web (PWA) | `flutter build web --dart-define-from-file=env/prod.json` |

## Estructura
```
lib/
├── main.dart              # ProviderScope + runApp
├── app.dart               # MaterialApp.router, temas
├── core/
│   ├── config/env.dart    # Variables por ambiente (--dart-define)
│   ├── network/           # Dio + interceptor JWT
│   ├── router/            # go_router y rutas
│   ├── storage/           # flutter_secure_storage (token)
│   └── theme/             # Material 3
└── features/<feature>/
    ├── data/              # repositorios, DTOs, llamadas API
    ├── domain/            # modelos y reglas
    └── presentation/      # páginas, widgets, providers
```

## Stack
Riverpod (estado/DI) · go_router (navegación) · Dio (HTTP) · flutter_secure_storage (JWT)
