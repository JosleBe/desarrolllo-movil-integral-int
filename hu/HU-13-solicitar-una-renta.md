# HU-13: Solicitar una renta

- **Épica:** Pagos y QR
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 22
- **Trazabilidad:** RF-09, RN-04

## Historia de usuario

**Como** Rentador, **quiero** solicitar la renta de un artículo indicando fechas y horarios, **para** reservarlo para el momento en que lo necesito.

## Criterios de aceptación

- [ ] La solicitud crea una renta en estado SOLICITADA.
- [ ] Dado que el artículo ya está reservado en ese lapso, cuando intento solicitarlo, entonces el sistema no lo permite.
- [ ] Si el artículo se vuelve no disponible, la renta pasa a RECHAZADA y se me notifica.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Modelo de renta y catálogo de estados | 4 |
| Backend | Endpoint de solicitud con validación de traslape de fechas | 6 |
| Backend | Transición a RECHAZADA y notificación | 3 |
| Frontend | Selección de fechas y horarios | 5 |
| Pruebas | Pruebas de concurrencia (RN-04) | 4 |
| | **Total estimado** | **22** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
