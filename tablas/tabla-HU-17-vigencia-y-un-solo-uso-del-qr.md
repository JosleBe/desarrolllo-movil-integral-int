# Tabla técnica — HU-17-vigencia-y-un-solo-uso-del-qr

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-17: Vigencia y un solo uso del QR** |
| **¿Qué comprueba?** | Al procesar un QR en su fase, el código vence automáticamente; un código usado, vencido o de fase incorrecta se rechaza en Recepción con mensaje claro. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | El primer procesamiento válido invalida el QR y una segunda petición no produce efectos; expiración y fase se verifican antes de aceptar. |


