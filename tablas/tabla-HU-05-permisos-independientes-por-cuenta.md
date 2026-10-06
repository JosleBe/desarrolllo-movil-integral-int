# Tabla técnica — HU-05-permisos-independientes-por-cuenta

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-05: Permisos independientes por cuenta** |
| **¿Qué comprueba?** | Se comprueban las cuatro combinaciones Rentador/Vendedor: cada permiso habilita solo su módulo, ambos habilita acceso completo y ambos inactivos deja navegación e historial; la autorización se aplica en servidor. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Las cuatro combinaciones producen exactamente los accesos definidos, incluyendo llamadas directas a endpoints protegidos, sin depender solo de ocultar menús. |


