# HU-15: Recibir mi boleto con QR único

- **Épica:** Pagos y QR
- **Prioridad:** Alta
- **Puntos:** 8
- **Horas estimadas:** 17
- **Trazabilidad:** RF-11, RNF-05

## Historia de usuario

**Como** Rentador, **quiero** obtener un código QR único al confirmarse mi pago, **para** presentarlo en Recepción para retirar el artículo.

## Criterios de aceptación

- [ ] El QR se genera automáticamente solo después de la confirmación del pago.
- [ ] El QR es único, está firmado digitalmente y no puede duplicarse.
- [ ] Puedo ver el boleto desde mi cuenta en cualquier momento.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Generación de QR único con firma digital | 6 |
| Backend | Endpoint del boleto | 3 |
| Frontend | Vista del boleto con QR | 4 |
| Pruebas | Pruebas de unicidad y firma | 4 |
| | **Total estimado** | **17** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
