# HU-26: Consultar la bitácora de auditoría

- **Épica:** Admin e Incidencias
- **Prioridad:** Media
- **Puntos:** 5
- **Horas estimadas:** 18
- **Trazabilidad:** RNF-08

## Historia de usuario

**Como** Administrador, **quiero** consultar el registro de acciones administrativas y cambios de estado críticos, **para** auditar lo ocurrido y detectar irregularidades.

## Criterios de aceptación

- [ ] La bitácora registra usuario, acción, fecha y hora, y estado anterior y nuevo.
- [ ] Puedo filtrar por usuario, tipo de acción y rango de fechas.
- [ ] Los registros no se pueden editar ni borrar.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Base de datos | Tabla de bitácora de solo inserción | 3 |
| Backend | Registro automático de acciones críticas | 5 |
| Backend | Consulta con filtros | 3 |
| Frontend | Vista de bitácora | 4 |
| Pruebas | Pruebas de inmutabilidad y filtros | 3 |
| | **Total estimado** | **18** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
