# HU-03: Inicio y cierre de sesión seguro

- **Épica:** Autenticación
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 18
- **Trazabilidad:** RF-03, RNF-02

## Historia de usuario

**Como** usuario verificado, **quiero** iniciar y cerrar sesión de forma segura, **para** proteger mi cuenta y mis datos.

## Criterios de aceptación

- [ ] Dadas credenciales correctas, cuando inicio sesión, entonces se emite una sesión encriptada/JWT con expiración.
- [ ] Dadas credenciales incorrectas, cuando intento ingresar, entonces se muestra un error genérico sin revelar cuál dato falló.
- [ ] Cuando cierro sesión, entonces el token queda invalidado y los endpoints privados dejan de responder.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Login y emisión de JWT con expiración | 4 |
| Backend | Middleware de autenticación para endpoints privados | 4 |
| Backend | Cierre de sesión e invalidación de token | 3 |
| Frontend | Pantalla de login y manejo de sesión | 4 |
| Pruebas | Pruebas de seguridad de sesión | 3 |
| | **Total estimado** | **18** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
