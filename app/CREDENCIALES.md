# SRUU — Credenciales y guía de prueba

> App móvil del Sistema de Renta de Útiles Universitarios (UTEZ).
> Actualmente funciona con **datos de prueba (mocks)**: no requiere backend
> ni conexión a internet. Todo el estado vive en memoria y se reinicia al
> cerrar la app.

## Cuentas precargadas

| Correo | Contraseña | Roles / permisos | Para qué sirve |
|---|---|---|---|
| `demo@utez.edu.mx` | `demo1234` | Rentador + Vendedor + Recepción + Admin | Probar **todas** las secciones |
| `laura@utez.edu.mx` | `laura1234` | Rentador + Vendedor | Flujo de renta y de publicaciones |
| `pedro@utez.edu.mx` | `pedro1234` | Solo Vendedor | Ver cómo se ocultan secciones sin permiso |

## Qué probar por rol (mapeo a historias de usuario)

### Autenticación (Épica 1 — HU-01 a HU-04)
- **Registro** (HU-01/02): en la pantalla de login, "Crear una cuenta". Usa un
  correo `@utez.edu.mx`; la app muestra el código de verificación en pantalla
  (modo desarrollo) para confirmar la cuenta.
- **Login/logout** (HU-03): con cualquiera de las cuentas de arriba.
- **Perfil** (HU-04): ícono de perfil (arriba a la derecha). Puedes editar
  nombre y teléfono, pero no el correo. Muestra tus permisos.

### Rentador (Épica 2 y 3)
- **Catálogo** (HU-10/11): buscar y filtrar útiles por categoría, periodo y
  disponibilidad.
- **Solicitar renta** (HU-13): abrir un útil disponible → "Solicitar renta"
  → elegir periodo y fechas.
- **Pagar** (HU-14): en "Mis solicitudes" → "Pagar". El interruptor
  "Simular pago exitoso" permite probar también un pago fallido y el reintento.
- **Boleto con QR** (HU-15): tras pagar, se genera el QR. Visible en
  "Mis solicitudes" → "Ver boleto".
- **Cancelar** (HU-16): solo mientras la solicitud no esté pagada.

### Vendedor (Épica 2)
- **Publicar** (HU-06): "Mis publicaciones" → botón "Publicar".
- **Editar / pausar / eliminar** (HU-07): en cada publicación.
- **Precios por periodo** (HU-08): hora / día / semana en el formulario.
- **Mis rentas** (HU-12): rentas de tus artículos, con filtro por estado.

### Recepción (Épica 4 — solo `demo`)
- Pestaña **Recepción** (HU-18): "Usar un QR de ejemplo" → "Validar QR".
- **Recibir** del vendedor (HU-19), **Entregar** al rentador (HU-20, requiere
  QR válido), **Registrar devolución** (HU-21).

### Administrador (Épica 5 — solo `demo`)
- Pestaña **Admin**:
  - **Incidencias** (HU-23): resolver reportes.
  - **Usuarios y permisos** (HU-24/25): suspender (con motivo obligatorio) o
    reactivar los permisos de Laura y Pedro.
  - **Bitácora** (HU-26): historial de acciones críticas, con filtros.
  - **Moderar catálogo** (HU-27): pausar o eliminar publicaciones con motivo.

## Cómo correr / actualizar la app

```bash
# Correr en el navegador (web / PWA)
flutter run -d chrome --dart-define-from-file=env/dev.json

# Correr en un celular conectado por USB (con depuración USB activada)
flutter run --dart-define-from-file=env/dev.json

# Generar el APK instalable
flutter build apk --release --dart-define-from-file=env/dev.json
# Resultado: build/app/outputs/flutter-apk/app-release.apk
```

> El APK listo para instalar también está copiado en
> `C:\Users\Admin\Desktop\Todo\SRUU.apk`.

## Notas

- La app usa mocks; cuando exista el backend, se conecta cambiando cada
  `*RepositoryProvider` (en `lib/features/*/presentation/providers/`) de la
  implementación `Mock...` a una con Dio, sin tocar la interfaz.
- En el emulador de Android, `localhost` del backend se apunta con `10.0.2.2`.
  En un celular físico se usaría la IP de la PC en la red local.
