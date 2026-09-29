# HU-16: Cancelar una solicitud antes de pagar

- **Épica:** Pagos y QR
- **Prioridad:** Media
- **Puntos:** 2
- **Horas estimadas:** 9
- **Trazabilidad:** Flujo de estados, RN-04

## Historia de usuario

**Como** Rentador, **quiero** cancelar mi solicitud mientras no haya pagado, **para** liberar la reserva si ya no necesito el artículo.

## Criterios de aceptación

- [ ] Dada una renta en estado SOLICITADA, cuando la cancelo, entonces pasa a CANCELADA.
- [ ] El artículo vuelve a estar disponible para esas fechas.
- [ ] Después del pago ya no puedo cancelar desde esta opción.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Endpoint de cancelación (solo en SOLICITADA) | 3 |
| Backend | Liberación de disponibilidad | 2 |
| Frontend | Botón de cancelar con confirmación | 2 |
| Pruebas | Pruebas de estados permitidos | 2 |
| | **Total estimado** | **9** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
