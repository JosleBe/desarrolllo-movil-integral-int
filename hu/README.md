# Historias de usuario — SRUU (UTEZ)

Esta carpeta contiene las **27 historias de usuario** (HU-01 a HU-27) del Sistema de Renta de Útiles Universitarios (SRUU) de la UTEZ, organizadas en 5 épicas. Cada archivo sigue una plantilla uniforme con criterios de aceptación, desglose de tareas y horas estimadas, de modo que el equipo pueda planificar sprints y hacer trazabilidad directa a los requerimientos del documento **DFR_SRUU**.

---

## Épica 1: Autenticación

> Requerimientos asociados: RF-01, RF-02, RF-03, RNF-01, RN-01

| ID | Título | Rol | Prioridad | Puntos | Horas |
|----|--------|-----|-----------|--------|-------|
| [HU-01](HU-01-registro-con-correo-institucional.md) | Registro con correo institucional | Alumno / Personal UTEZ | Alta | 5 | 16 |
| [HU-02](HU-02-verificacion-del-correo-por-token.md) | Verificación del correo por token | Alumno registrado | Alta | 3 | 15 |
| [HU-03](HU-03-inicio-y-cierre-de-sesion-seguro.md) | Inicio y cierre de sesión seguro | Usuario verificado | Alta | 5 | 18 |
| [HU-04](HU-04-gestion-de-perfil-e-historial.md) | Gestión de perfil e historial | Usuario Base | Media | 3 | 14 |

---

## Épica 2: Publicaciones

> Requerimientos asociados: RF-04, RF-05, RF-06, RF-07, RF-08, RNF-06

| ID | Título | Rol | Prioridad | Puntos | Horas |
|----|--------|-----|-----------|--------|-------|
| [HU-05](HU-05-permisos-independientes-por-cuenta.md) | Permisos independientes por cuenta | Usuario | Alta | 5 | 19 |
| [HU-06](HU-06-publicar-un-util.md) | Publicar un útil | Vendedor | Alta | 5 | 16 |
| [HU-07](HU-07-editar-pausar-y-eliminar-publicaciones.md) | Editar, pausar y eliminar publicaciones | Vendedor | Alta | 3 | 16 |
| [HU-08](HU-08-definir-precio-y-periodos-de-renta.md) | Definir precio y periodos de renta | Vendedor | Alta | 3 | 12 |
| [HU-09](HU-09-galeria-de-imagenes-por-articulo.md) | Galería de imágenes por artículo | Vendedor | Media | 5 | 20 |
| [HU-10](HU-10-busqueda-avanzada-en-el-catalogo.md) | Búsqueda avanzada en el catálogo | Usuario Base / Rentador | Alta | 5 | 16 |
| [HU-11](HU-11-disponibilidad-en-tiempo-real.md) | Disponibilidad en tiempo real | Rentador | Alta | 5 | 16 |
| [HU-12](HU-12-consultar-mis-rentas-activas.md) | Consultar mis rentas activas | Vendedor | Media | 3 | 9 |

---

## Épica 3: Pagos y QR

> Requerimientos asociados: RF-09, RF-10, RF-11, RNF-05, RN-04, RN-06

| ID | Título | Rol | Prioridad | Puntos | Horas |
|----|--------|-----|-----------|--------|-------|
| [HU-13](HU-13-solicitar-una-renta.md) | Solicitar una renta | Rentador | Alta | 5 | 22 |
| [HU-14](HU-14-pagar-la-renta.md) | Pagar la renta | Rentador | Alta | 8 | 21 |
| [HU-15](HU-15-recibir-mi-boleto-con-qr-unico.md) | Recibir mi boleto con QR único | Rentador | Alta | 8 | 17 |
| [HU-16](HU-16-cancelar-una-solicitud-antes-de-pagar.md) | Cancelar una solicitud antes de pagar | Rentador | Media | 2 | 9 |
| [HU-17](HU-17-vigencia-y-un-solo-uso-del-qr.md) | Vigencia y un solo uso del QR | Sistema | Alta | 5 | 11 |

---

## Épica 4: Recepción

> Requerimientos asociados: RF-12, RF-13, RF-14, RF-15, RNF-03, RN-05

| ID | Título | Rol | Prioridad | Puntos | Horas |
|----|--------|-----|-----------|--------|-------|
| [HU-18](HU-18-escanear-y-validar-el-qr.md) | Escanear y validar el QR | Personal de Recepción | Alta | 8 | 21 |
| [HU-19](HU-19-recibir-el-articulo-del-vendedor.md) | Recibir el artículo del Vendedor | Personal de Recepción | Alta | 5 | 13 |
| [HU-20](HU-20-entregar-el-articulo-al-rentador.md) | Entregar el artículo al Rentador | Personal de Recepción | Alta | 5 | 14 |
| [HU-21](HU-21-registrar-la-devolucion.md) | Registrar la devolución | Personal de Recepción | Alta | 5 | 15 |

---

## Épica 5: Admin e Incidencias

> Requerimientos asociados: RF-16, RF-17, RNF-08, RN-02, RN-03

| ID | Título | Rol | Prioridad | Puntos | Horas |
|----|--------|-----|-----------|--------|-------|
| [HU-22](HU-22-reportar-una-incidencia.md) | Reportar una incidencia | Vendedor / Rentador / Recepción | Alta | 5 | 17 |
| [HU-23](HU-23-resolver-incidencias.md) | Resolver incidencias | Administrador | Alta | 5 | 16 |
| [HU-24](HU-24-suspender-permisos-con-justificacion.md) | Suspender permisos con justificación | Administrador | Alta | 5 | 14 |
| [HU-25](HU-25-reactivar-permisos.md) | Reactivar permisos | Administrador | Media | 2 | 8 |
| [HU-26](HU-26-consultar-la-bitacora-de-auditoria.md) | Consultar la bitácora de auditoría | Administrador | Media | 5 | 18 |
| [HU-27](HU-27-moderar-el-catalogo.md) | Moderar el catálogo | Administrador | Baja | 3 | 11 |

---

## Totales por épica y general

| Épica | Historias | Puntos | Horas |
|-------|-----------|--------|-------|
| Épica 1: Autenticación | 4 | 16 | 63 |
| Épica 2: Publicaciones | 8 | 34 | 124 |
| Épica 3: Pagos y QR | 5 | 28 | 80 |
| Épica 4: Recepción | 4 | 23 | 63 |
| Épica 5: Admin e Incidencias | 6 | 25 | 84 |
| **TOTAL GENERAL** | **27** | **126** | **414** |

> De las 27 historias, **20 tienen prioridad Alta**.

---

## Definición de Hecho (DoD)

- El código cumple los criterios de aceptación y fue revisado por al menos otro integrante del equipo.
- Las pruebas unitarias y de integración pasan; los endpoints privados validan autenticación y autorización.
- La funcionalidad es usable en móvil y PC (diseño responsivo/PWA).
- Los cambios críticos generan registro en bitácora cuando aplica.
- El Product Owner revisó y aceptó la historia en la demostración del sprint.

---

## Convenciones

### Prioridad
| Valor | Significado |
|-------|-------------|
| Alta | Indispensable para el MVP |
| Media | Importante, puede entrar en el segundo sprint |
| Baja | Deseable |

### Puntos de historia (escala Fibonacci)
| Puntos | Complejidad aproximada |
|--------|------------------------|
| 1 | Trivial |
| 2 | Muy simple |
| 3 | Simple |
| 5 | Moderada |
| 8 | Compleja |

### Horas estimadas
Las horas son una **estimación inicial por tarea** y representan el esfuerzo individual esperado. Se recalibrarán en la reunión de planificación de cada sprint.
