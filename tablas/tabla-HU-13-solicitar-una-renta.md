# Tabla técnica — HU-13-solicitar-una-renta

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-13: Solicitar una renta** |
| **¿Qué comprueba?** | La solicitud con fechas y horarios válidos crea una renta SOLICITADA; un traslape se rechaza; si el artículo deja de estar disponible pasa a RECHAZADA y notifica al Rentador. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | La prueba de concurrencia impide reservas superpuestas, conserva la transición SOLICITADA o RECHAZADA adecuada y genera la notificación correspondiente. |


