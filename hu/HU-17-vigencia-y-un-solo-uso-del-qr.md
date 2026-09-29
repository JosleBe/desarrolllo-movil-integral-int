# HU-17: Vigencia y un solo uso del QR

- **Épica:** Pagos y QR
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 11
- **Trazabilidad:** RNF-05, RN-06

## Historia de usuario

**Como** Sistema, **quiero** invalidar cada QR una vez procesado en su fase, **para** evitar duplicaciones y usos indebidos del boleto.

## Criterios de aceptación

- [ ] Tras procesar el QR en una fase, este vence automáticamente.
- [ ] Un QR ya usado o vencido es rechazado con un mensaje claro en Recepción.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Invalidación del QR al procesar cada fase | 4 |
| Backend | Validación de fase y vigencia | 4 |
| Pruebas | Pruebas de reúso y QR vencido | 3 |
| | **Total estimado** | **11** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
