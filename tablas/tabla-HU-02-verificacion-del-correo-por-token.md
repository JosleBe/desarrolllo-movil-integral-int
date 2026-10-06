# Tabla técnica — HU-02-verificacion-del-correo-por-token

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-02: Verificación del correo por token** |
| **¿Qué comprueba?** | La creación de cuenta envía un token; un token válido y vigente cambia la cuenta a verificada con rol Usuario Base; uno vencido o usado no activa la cuenta y permite solicitar reenvío. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Se verifica el envío, la expiración y el consumo único del token, así como los estados y mensajes correctos para los tres escenarios. |


