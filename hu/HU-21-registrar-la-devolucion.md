# HU-21: Registrar la devolución

- **Épica:** Recepción
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 15
- **Trazabilidad:** RF-15, RF-16

## Historia de usuario

**Como** personal de Recepción, **quiero** registrar la devolución del Rentador y el retorno del artículo al Vendedor, **para** cerrar el ciclo de la renta y liberar el pago.

## Criterios de aceptación

- [ ] Al devolver, la renta pasa a DEVUELTA; al retornar al Vendedor, pasa a FINALIZADA.
- [ ] Si detecto daño o faltantes, puedo abrir una incidencia desde la misma pantalla.
- [ ] Quedan registrados fecha, hora y estado del artículo.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Registro de devolución y retorno (DEVUELTA y FINALIZADA) | 5 |
| Frontend | Pantalla de devolución con acceso a incidencia | 5 |
| Base de datos | Historial de estado del artículo | 2 |
| Pruebas | Pruebas del cierre de renta | 3 |
| | **Total estimado** | **15** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
