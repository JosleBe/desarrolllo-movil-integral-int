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
- Correos de prueba (código de verificación): http://localhost:8025
- Cuentas demo (las mismas del mock de la app): `demo@utez.edu.mx` / `demo1234` (todos los permisos), `laura@utez.edu.mx` / `laura1234`, `pedro@utez.edu.mx` / `pedro1234`.
- Sin backend, la app funciona con los repositorios mock: `--dart-define-from-file=env/dev.example.json` (`USE_API=false`).
- Si el puerto 8080 está ocupado, cambia el mapeo del backend en `docker-compose.yml` y `API_BASE_URL` en tu `env/*.json`.
