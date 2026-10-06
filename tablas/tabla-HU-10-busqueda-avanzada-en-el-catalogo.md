# Tabla técnica — HU-10-busqueda-avanzada-en-el-catalogo

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-10: Búsqueda avanzada en el catálogo** |
| **¿Qué comprueba?** | La búsqueda combina categoría, rango de precio, disponibilidad y periodo de renta, actualiza resultados con los filtros activos y comunica cuando no hay coincidencias. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Una consulta con varios filtros devuelve solo publicaciones que cumplen todos; quitar o cambiar filtros actualiza el conjunto y cero coincidencias muestra un estado explícito. |


