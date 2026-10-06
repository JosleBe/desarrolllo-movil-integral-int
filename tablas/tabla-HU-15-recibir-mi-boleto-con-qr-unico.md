# Tabla técnica — HU-15-recibir-mi-boleto-con-qr-unico

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-15: Recibir mi boleto con QR único** |
| **¿Qué comprueba?** | Tras confirmar el pago se genera automáticamente un QR único y firmado; no se genera antes, no se duplica y el Rentador puede consultar el boleto desde su cuenta. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Solo una renta CONFIRMADA obtiene boleto, la firma se valida y el identificador es único; la vista recupera el mismo boleto en consultas posteriores. |


