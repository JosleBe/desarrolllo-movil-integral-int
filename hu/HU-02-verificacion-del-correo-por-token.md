# HU-02: Verificación del correo por token

- **Épica:** Autenticación
- **Prioridad:** Alta
- **Puntos:** 3
- **Horas estimadas:** 15
- **Trazabilidad:** RF-02, RN-01

## Historia de usuario

**Como** alumno registrado, **quiero** recibir un enlace de verificación en mi correo institucional, **para** confirmar que el correo me pertenece y activar mi cuenta.

## Criterios de aceptación

- [ ] Dado un registro nuevo, cuando se crea la cuenta, entonces se envía un token de verificación al correo.
- [ ] Dado un token válido y vigente, cuando lo abro, entonces la cuenta pasa a estado verificado con rol Usuario Base.
- [ ] Dado un token vencido o ya usado, cuando lo abro, entonces se me ofrece reenviar uno nuevo.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Generación y expiración del token de verificación | 3 |
| Backend | Envío del correo de verificación | 4 |
| Backend | Endpoints de verificación y reenvío | 3 |
| Frontend | Pantallas de confirmación, error y reenvío | 3 |
| Pruebas | Pruebas de token vencido y ya usado | 2 |
| | **Total estimado** | **15** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
