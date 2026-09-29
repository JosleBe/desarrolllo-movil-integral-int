# HU-18: Escanear y validar el QR

- **Épica:** Recepción
- **Prioridad:** Alta
- **Puntos:** 8
- **Horas estimadas:** 21
- **Trazabilidad:** RF-12, RNF-03, RNF-04

## Historia de usuario

**Como** personal de Recepción, **quiero** escanear un QR y ver los datos del artículo, el rentador y el vendedor, **para** validar identidades y la información de la transacción.

## Criterios de aceptación

- [ ] El escaneo y la validación responden en menos de 2 segundos.
- [ ] Un QR falso, vencido o de otra fase se rechaza y se avisa al operador.
- [ ] La pantalla funciona en móvil y tablet.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Frontend | Escáner de QR con cámara móvil | 6 |
| Backend | Endpoint de validación de firma y datos | 5 |
| Backend | Optimización para responder en menos de 2 s | 3 |
| Frontend | Pantalla de datos de la transacción | 4 |
| Pruebas | Pruebas de rendimiento y QR inválidos | 3 |
| | **Total estimado** | **21** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
