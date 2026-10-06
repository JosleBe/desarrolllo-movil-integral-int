# Tabla técnica — HU-01-registro-con-correo-institucional

> Matriz de validación funcional y técnica.

| **Campo** | **Detalle** |
|:---|:---|
| **Historia de usuario** | **HU-01: Registro con correo institucional** |
| **¿Qué comprueba?** | La validación de dominio permite registrarse únicamente con correo @utez.edu.mx; un correo externo se rechaza con mensaje claro; un correo válido crea la cuenta pendiente de verificación y la contraseña queda almacenada mediante BCrypt o Argon2. |
| **Tipo de prueba** | Interfaz, unitaria e integración |
| **Criterio de aprobación** | Con datos válidos se crea una cuenta pendiente; con dominio distinto se rechaza; la prueba de persistencia confirma correo único y hash no reversible. |


