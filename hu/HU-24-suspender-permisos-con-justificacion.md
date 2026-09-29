# HU-24: Suspender permisos con justificación

- **Épica:** Admin e Incidencias
- **Prioridad:** Alta
- **Puntos:** 5
- **Horas estimadas:** 14
- **Trazabilidad:** RF-17, RN-02, RN-03

## Historia de usuario

**Como** Administrador, **quiero** suspender el permiso de Rentador o de Vendedor de un usuario, **para** aplicar sanciones ante incumplimientos.

## Criterios de aceptación

- [ ] El sistema exige registrar el motivo; sin motivo no se puede suspender.
- [ ] Suspender un permiso no afecta automáticamente al otro permiso.
- [ ] El usuario ve el estado de su permiso suspendido y el motivo.

## Desglose de tareas

| Área | Tarea | Horas |
|------|-------|-------|
| Backend | Endpoint de suspensión con motivo obligatorio (RN-03) | 4 |
| Backend | Aislamiento de efectos por permiso (RN-02) | 3 |
| Frontend | Ventana de suspensión y aviso al usuario | 4 |
| Pruebas | Pruebas de independencia de permisos | 3 |
| | **Total estimado** | **14** |

## Notas

_(Espacio vacío para notas del equipo, decisiones técnicas y enlaces a PRs o issues.)_
