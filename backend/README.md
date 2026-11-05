# SRUU — Backend

Spring Boot 4.1 · Java 21 · PostgreSQL 17 · Flyway · Spring Security (JWT HS256) · BCrypt.

## Correr en local
```bash
docker compose up -d db mail                     # desde la raíz del repo
SRUU_SEED_DEMO=true ./mvnw spring-boot:run       # API en http://localhost:8080/api
```
- Base de datos: `localhost:55432` (usuario/clave/base `sruu`).
- Bandeja de correo (Mailpit): http://localhost:8025

## Pruebas
```bash
./mvnw test     # usa Testcontainers: necesita Docker encendido
```

## Configuración
| Variable | Por defecto | Uso |
|---|---|---|
| `SRUU_DB_URL` / `SRUU_DB_USER` / `SRUU_DB_PASSWORD` | `jdbc:postgresql://localhost:55432/sruu`, `sruu`, `sruu` | Conexión a PostgreSQL |
| `SRUU_JWT_SECRET` | clave de desarrollo | Clave HMAC (≥ 32 bytes). **Obligatoria en producción.** |
| `SRUU_JWT_TTL` | `8h` | Vigencia de la sesión |
| `SRUU_MAIL_HOST` / `SRUU_MAIL_PORT` | `localhost` / `1025` | SMTP |
| `SRUU_WEB_BASE_URL` | `http://localhost:8686` | Base del enlace de verificación del correo |
| `SRUU_CORS_ORIGINS` | `http://localhost:*` | Orígenes permitidos |
| `SRUU_SEED_DEMO` | `false` | Crea la cuenta demo verificada |

## Estructura
```
mx.edu.utez.sruu
├── auth/     # HU-01..03: registro, verificación por token, login/logout JWT
├── user/     # Usuario, estado de cuenta y rol
├── common/   # Errores {code, message}
└── config/   # Seguridad, CORS, propiedades, reloj, datos demo
```
Contrato de la API: [`app/docs/auth-api.md`](../app/docs/auth-api.md).
