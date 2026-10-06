# Tabla técnica — HU-20-entregar-el-articulo-al-rentador

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-20: Entregar el artículo al Rentador** |
| **¿Qué comprueba?** | La entrega solo se registra después de validar exitosamente el QR; al completarse, la renta pasa a ENTREGADA y luego a EN RENTA. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Una entrega sin QR válido es bloqueada, una con QR correcto registra las dos transiciones en orden y no permite duplicar la entrega. |


