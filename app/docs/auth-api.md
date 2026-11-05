# Contrato de API — Épica 1 (Autenticación, HU-01 a HU-04)

Implementado en [`backend/`](../../backend) (Spring Boot). Base local: `http://localhost:8080/api`.
En la app lo consume `ApiAuthRepository` (`lib/features/auth/data/`), que cumple el mismo
contrato `AuthRepository` que `MockAuthRepository`; se activa con `USE_API=true`.

Los errores responden `{ "code": "CODIGO", "message": "texto" }`.

## Usuario
```json
{ "id": "uuid", "email": "20223tn067@utez.edu.mx", "fullName": "Nombre Apellido",
  "phone": "7771234567",
  "status": "PENDIENTE_VERIFICACION | VERIFICADA", "role": "NINGUNO | USUARIO_BASE",
  "permissions": { "renter": true, "seller": false, "reception": false, "admin": false } }
```
`phone` se omite si está vacío. `permissions` es el `UserPermissions` de la app (DFR sección 5).

## Endpoints

| Método | Ruta | Cuerpo | Éxito | Errores |
|---|---|---|---|---|
| POST | `/auth/register` | `{fullName, email, password}` | `201 {user}` pendiente, sin permisos | `422 INSTITUTIONAL_EMAIL_REQUIRED`, `409 EMAIL_ALREADY_REGISTERED`, `400 WEAK_PASSWORD`, `400 VALIDATION_ERROR {fields}` |
| POST | `/auth/verify` | `{email, code}` | `200 {user}` verificada, `role=USUARIO_BASE` | `400 TOKEN_INVALID`, `410 TOKEN_EXPIRED`, `429 TOO_MANY_ATTEMPTS` |
| POST | `/auth/verify/resend` | `{email}` | `202` (igual exista o no el correo) | `429 RATE_LIMITED` |
| POST | `/auth/login` | `{email, password}` | `200 {accessToken, expiresAt, user}` | `401 INVALID_CREDENTIALS`, `403 EMAIL_NOT_VERIFIED` |
| POST | `/auth/logout` | — (Bearer) | `204` | `401` |
| GET | `/auth/me` | — (Bearer) | `200 user` | `401` |
| PATCH | `/users/me` | `{fullName?, phone?}` (Bearer) | `200 user` | `403 PROFILE_READ_ONLY`, `400 VALIDATION_ERROR` |
| GET | `/admin/users` | — (Bearer, admin) | `200 [user]` ordenados por nombre | `403 FORBIDDEN` |
| PATCH | `/admin/users/{id}/permissions` | `{permission: RENTER\|SELLER, active, reason?}` (Bearer, admin) | `200 user` | `403 FORBIDDEN`, `404 USER_NOT_FOUND` |

## Cómo traduce la app cada error (`AuthException`)
| Código | Excepción |
|---|---|
| `INSTITUTIONAL_EMAIL_REQUIRED` | `InvalidInstitutionalEmail` |
| `EMAIL_ALREADY_REGISTERED` | `EmailAlreadyRegistered` |
| `INVALID_CREDENTIALS` | `InvalidCredentials` (mensaje genérico) |
| `EMAIL_NOT_VERIFIED` | `AccountNotVerified` |
| `TOKEN_INVALID`, `TOKEN_EXPIRED` | `InvalidVerificationToken` |
| `TOO_MANY_ATTEMPTS`, `RATE_LIMITED` | `TooManyAttempts` |
| `PROFILE_READ_ONLY`, `FORBIDDEN` | `PermissionDenied` |
| `WEAK_PASSWORD`, `VALIDATION_ERROR` | `InvalidAuthData` |
| sin red | `AuthNetworkError` |

## Reglas que cumple el servidor
- **HU-01**: dominio validado en el servidor (`^[^@]+@utez\.edu\.mx$`, en minúsculas); correo único sin distinguir mayúsculas; contraseña de 8 a 72 caracteres (la misma regla que la app) guardada con **BCrypt costo 12**; nunca se devuelve el hash.
- **HU-02**: código de **6 dígitos** enviado por correo; se guarda solo `SHA-256(idUsuario:código)`; vigencia de 24 h; un solo uso; solo vale el último código; **5 intentos fallidos** lo invalidan; reenviar invalida los anteriores y tiene espera de 60 s. Correo desconocido, cuenta ya verificada y código incorrecto responden igual (`TOKEN_INVALID`) para no revelar cuentas.
- **HU-03**: JWT HS256 con `exp` (8 h) y `jti`; `INVALID_CREDENTIALS` idéntico para correo inexistente y contraseña incorrecta (mismo tiempo de respuesta); `logout` agrega el `jti` a la lista de revocación y los endpoints privados responden `401`.
- **HU-04**: solo se editan nombre y teléfono; el correo no cambia. Con Rentador y Vendedor inactivos el perfil es de solo lectura (`403 PROFILE_READ_ONLY`), aunque sí puede consultarse.
- **HU-05 / HU-24 / HU-25**: los permisos se validan en el servidor; solo una cuenta con `admin` lista cuentas y cambia permisos, y cambiar uno no afecta al otro (RN-02). `reason` se acepta para la bitácora de la Épica 5.
