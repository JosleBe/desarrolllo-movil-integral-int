# Tabla técnica — HU-16-cancelar-una-solicitud-antes-de-pagar

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-16: Cancelar una solicitud antes de pagar** |
| **¿Qué comprueba?** | Una renta SOLICITADA puede pasar a CANCELADA y liberar sus fechas; una renta ya pagada no puede cancelarse mediante esta opción. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | El botón y endpoint solo aceptan SOLICITADA, la disponibilidad vuelve a libre y cualquier estado posterior al pago recibe rechazo sin alterar la renta. |


