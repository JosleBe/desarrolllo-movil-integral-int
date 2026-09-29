# HU-06: Publicar un útil

- **Épica:** Publicaciones
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 16
- **Trazabilidad:** RF-05

## Historia de usuario

**Como** Vendedor, **quiero** crear una publicación con nombre, descripción, categoría y estado del artículo, **para** ofrecer mi material académico en renta.

## Criterios de aceptación

- [ ] Dado el permiso de Vendedor activo, cuando completo los campos obligatorios, entonces la publicación se crea y aparece en el catálogo.
- [ ] Dado que no tengo permiso de Vendedor activo, cuando intento acceder al módulo, entonces se me deniega el acceso.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Modelo de publicación y categorías | 4 |
| Backend | Endpoint de creación de publicación | 4 |
| Frontend | Formulario de publicación | 5 |
| Pruebas | Pruebas de permiso y campos obligatorios | 3 |
| | **Total estimado** | **16** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
