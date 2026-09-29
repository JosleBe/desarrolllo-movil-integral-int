# HU-22: Reportar una incidencia

- **Épica:** Admin e Incidencias
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 17
- **Trazabilidad:** RF-16

## Historia de usuario

**Como** Vendedor, Rentador o Recepción, **quiero** registrar un reporte de daño, demora o artículo faltante, **para** dejar constancia y que el caso sea atendido.

## Criterios de aceptación

- [ ] Puedo elegir el tipo de incidencia (daño, demora, faltante o no entregado) y adjuntar descripción.
- [ ] Al registrarla, la renta pasa a estado INCIDENCIA.
- [ ] Los involucrados reciben una notificación.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Modelo de incidencias | 3 |
| Backend | Creación de incidencia y transición a INCIDENCIA | 4 |
| Backend | Notificaciones a los involucrados | 3 |
| Frontend | Formulario de reporte | 4 |
| Pruebas | Pruebas por tipo de incidencia | 3 |
| | **Total estimado** | **17** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
