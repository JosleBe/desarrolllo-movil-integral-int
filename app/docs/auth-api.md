# Contrato de API — Épica 1 (Autenticación)

Lo que la app espera del backend para HU-01, HU-02 y HU-03. Base: `API_BASE_URL`.
Los errores responden `{ "code": "CODIGO", "message": "texto" }`.

## Usuario
```json
{ "id": "123", "email": "20223tn067@utez.edu.mx", "fullName": "Nombre Apellido",
  "status": "PENDIENTE_VERIFICACION | VERIFICADA", "role": "NINGUNO | USUARIO_BASE" }
```

## Endpoints

| Método | Ruta | Cuerpo | Éxito | Errores |
|---|---|---|---|---|
| POST | `/auth/register` | `{fullName, email, password}` | `201 {user}` con `status=PENDIENTE_VERIFICACION` | `422 INSTITUTIONAL_EMAIL_REQUIRED`, `409 EMAIL_ALREADY_REGISTERED` |
| POST | `/auth/verify` | `{token}` | `200 {user}` con `status=VERIFICADA`, `role=USUARIO_BASE` | `410 TOKEN_EXPIRED {email}`, `409 TOKEN_ALREADY_USED {email}`, `404 TOKEN_INVALID` |
| POST | `/auth/verify/resend` | `{email}` | `202` (igual exista o no el correo) | `429 RATE_LIMITED` |
| POST | `/auth/login` | `{email, password}` | `200 {accessToken, expiresAt (ISO-8601), user}` | `401 INVALID_CREDENTIALS`, `403 EMAIL_NOT_VERIFIED` |
| POST | `/auth/logout` | — (Bearer) | `204` | `401` |
| GET | `/auth/me` | — (Bearer) | `200 user` | `401` |

## Reglas que el servidor debe cumplir
- **HU-01**: validar el dominio en el servidor (`^[^@]+@utez\.edu\.mx$`, en minúsculas); correo único; contraseña con **BCrypt (cost ≥ 12) o Argon2id**; nunca devolver ni registrar el hash.
- **HU-02**: token aleatorio de ≥ 128 bits guardado como hash; vigencia de 24 h; un solo uso; al reenviar se invalidan los anteriores. El enlace del correo apunta a `https://<host-web>/verificar?token=<token>`.
- **HU-03**: JWT firmado con `exp` (la app usa `expiresAt` para cerrar sesión sola) y `jti`; `INVALID_CREDENTIALS` idéntico para correo inexistente y contraseña incorrecta; `logout` agrega el `jti` a una lista de revocación y el middleware de endpoints privados la consulta (responde `401`). `403 EMAIL_NOT_VERIFIED` solo con contraseña correcta.
