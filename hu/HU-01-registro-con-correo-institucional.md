# HU-01: Registro con correo institucional

- **Épica:** Autenticación
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 16
- **Trazabilidad:** RF-01, RN-01, RNF-01

## Historia de usuario

**Como** alumno o personal de la UTEZ, **quiero** registrarme con mi correo @utez.edu.mx, **para** acceder a la plataforma como parte de la comunidad universitaria.

## Criterios de aceptación

- [ ] Dado un correo con dominio distinto a @utez.edu.mx, cuando intento registrarme, entonces el sistema rechaza el registro y muestra un mensaje claro.
- [ ] Dado un correo institucional válido, cuando completo el formulario, entonces se crea la cuenta en estado pendiente de verificación.
- [ ] La contraseña se almacena con hash seguro (BCrypt o Argon2).

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Modelo de usuarios (correo único, estado de cuenta) | 3 |
| Backend | Endpoint de registro con validación del dominio @utez.edu.mx | 4 |
| Backend | Hash de contraseña con BCrypt/Argon2 | 2 |
| Frontend | Formulario de registro con validaciones | 4 |
| Pruebas | Pruebas de dominio válido e inválido | 3 |
| | **Total estimado** | **16** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
