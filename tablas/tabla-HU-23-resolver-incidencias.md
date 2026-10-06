# Tabla técnica — HU-23-resolver-incidencias

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-23: Resolver incidencias** |
| **¿Qué comprueba?** | El Administrador consulta detalle, evidencias e historial de la renta, registra una resolución, cambia el estado y deja cada cambio en la bitácora. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Solo el rol Administrador puede resolver; la resolución y nuevo estado quedan persistidos junto con un evento de auditoría verificable. |


