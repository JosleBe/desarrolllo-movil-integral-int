# HU-05: Permisos independientes por cuenta

- **Épica:** Publicaciones
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 19
- **Trazabilidad:** RF-04, RNF-02, Matriz de permisos

## Historia de usuario

**Como** usuario, **quiero** que mis permisos de Rentador y Vendedor funcionen de forma independiente, **para** ver y usar únicamente los módulos que tengo habilitados.

## Criterios de aceptación

- [ ] Solo Rentador activo: puede buscar y rentar, sin acceso al módulo de publicación.
- [ ] Solo Vendedor activo: puede publicar, sin poder rentar artículos de terceros.
- [ ] Ambos activos: acceso completo. Ambos inactivos: solo navegación e historial.
- [ ] Los permisos se validan en el servidor, no solo en la interfaz.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Modelo de permisos Rentador/Vendedor independientes | 4 |
| Backend | Middleware de autorización por atributos (ABAC) | 5 |
| Frontend | Menús y rutas según permisos activos | 4 |
| Frontend | Vista de Perfil Restringido | 2 |
| Pruebas | Pruebas de las 4 combinaciones de la matriz | 4 |
| | **Total estimado** | **19** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
