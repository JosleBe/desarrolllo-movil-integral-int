# Tabla técnica — HU-14-pagar-la-renta

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-14: Pagar la renta** |
| **¿Qué comprueba?** | Un pago exitoso transita la renta a PAGADA y después CONFIRMADA; un fallo la deja sin confirmar y permite reintento; cada intento registra fecha, monto y referencia. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | La integración distingue éxito y fallo de la pasarela, evita confirmar pagos fallidos o duplicados y persiste el comprobante mínimo de cada pago. |


