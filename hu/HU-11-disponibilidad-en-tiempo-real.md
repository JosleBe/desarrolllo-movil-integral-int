# HU-11: Disponibilidad en tiempo real

- **Épica:** Publicaciones
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 16
- **Trazabilidad:** RF-08, RN-04

## Historia de usuario

**Como** Rentador, **quiero** ver la disponibilidad actual de cada artículo, **para** saber si puedo rentarlo en las fechas que necesito.

## Criterios de aceptación

- [ ] El catálogo indica si el artículo está disponible o no para las fechas consultadas.
- [ ] Cuando otro usuario reserva el artículo, la disponibilidad se actualiza sin recargar manualmente.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Cálculo de disponibilidad por rango de fechas | 5 |
| Backend | Actualización en tiempo real (WebSocket o polling) | 5 |
| Frontend | Indicador de disponibilidad en el catálogo | 3 |
| Pruebas | Pruebas de actualización y consistencia | 3 |
| | **Total estimado** | **16** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
