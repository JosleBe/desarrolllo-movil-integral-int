# HU-20: Entregar el artículo al Rentador

- **Épica:** Recepción
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 14
- **Trazabilidad:** RF-14, RN-05

## Historia de usuario

**Como** personal de Recepción, **quiero** entregar el artículo solo tras un escaneo exitoso del QR, **para** garantizar que lo recibe la persona correcta.

## Criterios de aceptación

- [ ] Sin escaneo exitoso del QR, el sistema no permite registrar la entrega.
- [ ] Tras la entrega, la renta pasa a ENTREGADA y luego a EN RENTA.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Bloqueo de entrega sin QR validado (RN-05) | 4 |
| Backend | Transiciones a ENTREGADA y EN RENTA | 3 |
| Frontend | Pantalla de entrega | 4 |
| Pruebas | Pruebas de entrega con y sin QR | 3 |
| | **Total estimado** | **14** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
