# Tabla técnica — HU-03-inicio-y-cierre-de-sesion-seguro

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-03: Inicio y cierre de sesión seguro** |
| **¿Qué comprueba?** | Credenciales correctas producen una sesión JWT/encriptada con expiración; credenciales incorrectas muestran un error genérico; cerrar sesión invalida el token y bloquea endpoints privados. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | El login y logout cumplen las transiciones esperadas, no revelan si falló usuario o contraseña y una solicitud autenticada con token invalidado recibe rechazo. |


