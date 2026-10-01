# HU-10: Búsqueda avanzada en el catálogo

## 1. Alcance del esquema

Validar que el usuario pueda buscar útiles dentro del catálogo aplicando filtros combinados por:

- categoría
- rango de precio
- disponibilidad
- período de renta

Este alcance se centra en la funcionalidad principal de la búsqueda avanzada y en la coherencia entre la interfaz, la lógica de filtrado y los resultados que se muestran al usuario.

## 2. Esquema

### ¿Qué comprueba?

Comprueba que:

- el catálogo permite combinar varios filtros sin perder la lógica de búsqueda
- los resultados muestran solo los artículos que cumplen con todos los criterios seleccionados
- la disponibilidad y el período de renta se consideran en la validación de resultados
- cuando no existen coincidencias, se presenta un mensaje claro y consistente
- el usuario puede limpiar o cambiar filtros y consultar nuevamente el catálogo sin errores

### Tipo

- Interfaz: sí, porque la experiencia del usuario depende de los filtros en pantalla y de la forma en que se muestran los resultados.
- Integración: sí, porque la búsqueda combina la parte visual con la lógica de negocio y la respuesta del sistema.
- Unitaria: sí, puede aplicarse a la lógica de filtrado individualmente para validar que cada criterio funciona correctamente de manera aislada.

### Criterio de aprobación

Se aprueba porque la búsqueda debe devolver únicamente los elementos que cumplen con todas las condiciones solicitadas y no con una parte de ellas. Si se acepta una búsqueda incompleta, incorrecta o inconsistente, la funcionalidad no cumple con el propósito de la historia: encontrar el útil correcto con rapidez y seguridad.

Por eso se exige que:

- los filtros se combinen correctamente
- la lógica de resultados respete todas las condiciones simultáneamente
- el sistema maneje correctamente el caso sin coincidencias
- la interfaz muestre el estado del catálogo de forma coherente

Si no se cumple esta lógica, la búsqueda avanzaría de forma errónea y no sería aceptable para la historia de usuario.

## 3. Qué queda fuera

Queda fuera de esta prueba:

- la creación o edición de publicaciones
- la gestión de pagos o reservas
- la validación de autenticación de usuarios
- la lógica de notificaciones push o correo
- la comparación entre múltiples artículos
- la recomendación inteligente o sugerencias automáticas
- la geolocalización o búsqueda por ubicación física
- mejoras visuales o personalización avanzada del catálogo

## Resultado esperado

La HU-10 queda aprobada cuando el usuario puede navegar, filtrar y consultar el catálogo de forma intuitiva, con resultados precisos, mensajes de vacío adecuados y una experiencia consistente entre la interfaz y la lógica de búsqueda.
