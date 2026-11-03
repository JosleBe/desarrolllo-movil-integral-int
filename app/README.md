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
Con `"USE_FAKE_API": "true"` (ya viene en `dev.example.json`) la app usa un backend simulado en memoria con las mismas reglas que el real. Cuenta verificada: `demo@utez.edu.mx` / `Demo1234`. Al registrarte, la pantalla de verificación muestra una *bandeja de prueba* con el enlace del correo (y la opción de abrirlo ya vencido). Nunca se activa con `ENV=prod`.

## Autenticación (Épica 1)
| HU | Pantallas | Ruta |
|---|---|---|
| HU-01 Registro | Crear cuenta | `/registro` |
| HU-02 Verificación | Activa tu cuenta · Resultado del enlace | `/registro/pendiente`, `/verificar?token=` |
| HU-03 Sesión | Iniciar sesión · Inicio con cerrar sesión | `/login`, `/` |

Contrato con el backend: [`docs/auth-api.md`](docs/auth-api.md).

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
│   ├── storage/           # flutter_secure_storage (JWT + expiración)
│   ├── theme/             # Tipografía base
│   └── widgets/           # Sistema de frases (escenas, voces, campos)
└── features/<feature>/
    ├── data/              # repositorios, DTOs, llamadas API
    ├── domain/            # modelos y reglas
    └── presentation/      # páginas, widgets, providers
```

## Stack
Riverpod (estado/DI) · go_router (navegación) · Dio (HTTP) · flutter_secure_storage (JWT)

## Diseño
Cada pantalla es **una frase que completas**: "Soy ___ @utez.edu.mx y mi clave es ___". La app habla en peso medio y lo que tú escribes aparece en negritas y en otro color, dentro de la misma frase. El dominio institucional es parte fija de la oración, así que no hay forma de escribir otro (HU-01).

Cada momento del flujo tiene su color de fondo y el fondo transita de uno a otro: menta para entrar, verde UTEZ para registrarte o al quedar verificado, índigo mientras esperas el correo y rojo si un enlace no sirve. No hay tarjetas ni cajas: los campos son líneas subrayadas con la misma tipografía de la frase, los errores son resaltados de marcador y la acción principal es una barra a todo lo ancho abajo. Nunca se usan mayúsculas con espaciado.

Piezas en `lib/core/widgets/sentence.dart` (`SentenceScaffold`, `Say`, `you()`, `SentenceField`, `MatriculaField`, `Note`, `ActionBar`). Tipografías (SIL OFL, en `assets/fonts`): Bricolage Grotesque para la frase y Atkinson Hyperlegible para el texto de apoyo.
