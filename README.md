# SRUU — Sistema de Renta de Útiles Universitarios (UTEZ)

Monorepo del proyecto integrador.

| Carpeta | Qué es |
|---|---|
| [`app/`](app/README.md) | App Flutter (Android, iOS y Web/PWA) |
| [`backend/`](backend/README.md) | API REST en Spring Boot 4 + PostgreSQL |
| [`hu/`](hu/README.md) | Historias de usuario |

## Levantar todo en local
```bash
docker compose up -d --build          # PostgreSQL, Mailpit y el backend en :8080
cd app && flutter run -d chrome --web-port 8686 --dart-define-from-file=env/local.example.json
```
- Correos de prueba (verificación de cuenta): http://localhost:8025
- Cuenta demo: `demo@utez.edu.mx` / `Demo1234`
- Sin backend, la app también funciona en modo demo: `--dart-define-from-file=env/dev.example.json`.
