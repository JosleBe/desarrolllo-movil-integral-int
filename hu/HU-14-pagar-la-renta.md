# HU-14: Pagar la renta

- **Épica:** Pagos y QR
- **Prioridad:** Alta
- **Puntos:** 8
- **Horas estimadas:** 21
- **Trazabilidad:** RF-10

## Historia de usuario

**Como** Rentador, **quiero** pagar mi renta mediante la pasarela de pagos, **para** confirmar mi reserva.

## Criterios de aceptación

- [ ] Con un pago exitoso, la renta pasa a PAGADA y luego a CONFIRMADA.
- [ ] Si el pago falla, la renta permanece sin confirmar y puedo reintentar.
- [ ] Cada pago queda registrado con fecha, monto y referencia.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Integración con la pasarela de pagos | 8 |
| Backend | Registro del pago y transiciones PAGADA y CONFIRMADA | 4 |
| Frontend | Flujo de pago y reintento | 5 |
| Pruebas | Pruebas de pago exitoso y fallido | 4 |
| | **Total estimado** | **21** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
