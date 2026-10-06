# Tabla técnica — HU-11-disponibilidad-en-tiempo-real

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-11: Disponibilidad en tiempo real** |
| **¿Qué comprueba?** | El catálogo determina disponibilidad para las fechas consultadas y actualiza el indicador sin recarga manual cuando otro usuario reserva el artículo. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Los rangos ocupados y libres se calculan correctamente y una reserva concurrente actualiza la vista o evento suscrito sin mostrar disponibilidad obsoleta. |


