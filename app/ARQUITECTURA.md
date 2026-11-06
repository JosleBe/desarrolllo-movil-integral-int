# Arquitectura y patrones de diseño — SRUU (Frontend Flutter)

> Documento de referencia para el equipo. Explica **qué patrones de diseño**
> se usaron y **cómo está estructurado** el proyecto, de modo que al subirlo
> a un repositorio Git y seguir desarrollando se respete la misma
> metodología.

---

## 1. Arquitectura general

El proyecto sigue una arquitectura **Feature-First + Capas limpias (Clean
Architecture simplificada)**. Es decir:

- El código se organiza **por funcionalidad** (feature), no por tipo de
  archivo.
- Dentro de cada feature hay **tres capas** con dependencias en una sola
  dirección:

```
presentation  ──►  domain  ◄──  data
   (UI)          (contratos)     (implementaciones)
```

- **domain**: el "qué". Modelos puros y **contratos** (interfaces
  `abstract interface class`). No sabe de Flutter, HTTP ni JSON.
- **data**: el "cómo". Implementaciones concretas de los contratos
  (hoy *mocks* en memoria; mañana, API con Dio).
- **presentation**: la interfaz (páginas, widgets) y el estado (providers
  de Riverpod). Depende de `domain`, **nunca** de `data` directamente.

> Regla de oro: la UI y los controladores dependen de **abstracciones**
> (`domain`), no de implementaciones. Por eso cambiar de *mock* a *backend
> real* no obliga a tocar la interfaz.

---

## 2. Patrones de diseño utilizados

| Patrón | Dónde vive | Para qué se usa |
|---|---|---|
| **Repository** | `*/domain/*_repository.dart` + `*/data/mock_*.dart` | Aísla el origen de datos tras una interfaz. La UI pide datos al contrato sin saber si vienen de memoria, de una API o de una base de datos. |
| **Dependency Injection** | `*/presentation/providers/*.dart` (Riverpod `Provider`) | Los repositorios y controladores se **inyectan** vía Riverpod. Cambiar una implementación es cambiar **una línea** del provider. |
| **Strategy** | `AuthRepository`, `ListingRepository`, `RentalRepository` (interfaz) con sus `Mock...` | Cada contrato admite implementaciones intercambiables (estrategias). Hoy la estrategia es "mock en memoria"; se puede sustituir por "API Dio" sin afectar al resto. |
| **State / Observer** | `Notifier` / `NotifierProvider` (p. ej. `AuthController`, `CatalogFiltersController`) | El estado es observable: la UI se **suscribe** (`ref.watch`) y se reconstruye sola cuando el estado cambia. |
| **Adapter** | `qr_validator.dart`, DTOs implícitos en los mocks | Traduce entre el formato externo (payload del QR `SRUU|token|fase|firma`) y los modelos del dominio. |
| **Facade** | `AdminActions`, `ListingActions`, `RentalActions`, `ReceptionActions` | Exponen operaciones de alto nivel (p. ej. `suspendPermission`, `pay`, `deliver`) que por dentro orquestan repositorio + bitácora + refresco de providers. |
| **Value Object / Inmutabilidad** | `User`, `Listing`, `Rental`, `QrTicket`, `AuditEntry`, enums | Modelos inmutables con `copyWith`; los cambios producen copias nuevas, nunca mutaciones en sitio. La bitácora (`AuditEntry`) es de solo inserción (RNF-08). |

---

## 3. Estructura de carpetas

```
lib/
├── main.dart                 # Punto de entrada: ProviderScope + runApp
├── app.dart                  # MaterialApp.router, temas, router
│
├── core/                     # Infraestructura transversal (sin lógica de negocio)
│   ├── config/   env.dart            # Variables por ambiente (--dart-define)
│   ├── network/  api_client.dart     # Dio + interceptor JWT (para el backend futuro)
│   ├── router/   app_router.dart     # go_router: rutas y guard de sesión
│   ├── storage/  token_storage.dart  # Almacenamiento seguro del token (JWT)
│   ├── theme/    app_theme.dart      # Material 3, estilos y transiciones
│   └── widgets/  pressable_scale.dart# Widgets reutilizables (efectos de UI)
│
└── features/                 # Una carpeta por funcionalidad
    ├── auth/                 # Épica 1: autenticación y perfil
    ├── catalog/              # Épica 2: publicaciones y catálogo
    ├── rentals/              # Épica 3: solicitud, pago y QR
    ├── reception/            # Épica 4: módulo de Recepción
    ├── admin/                # Épica 5: incidencias, permisos, bitácora, moderación
    └── home/                 # Shell de navegación (menú según permisos)
```

Cada feature repite el mismo esqueleto de 3 capas:

```
features/<feature>/
├── domain/        # Modelos + contratos (interfaces) + excepciones
├── data/          # Implementaciones de los contratos (mocks en memoria)
└── presentation/
    ├── providers/ # Riverpod: repositorios inyectados, estado y "actions"
    ├── widgets/   # Widgets reutilizables de la feature
    └── *_page.dart# Pantallas
```

---

## 4. Stack técnico

| Herramienta | Rol |
|---|---|
| **Flutter / Dart** | Framework de UI multiplataforma (móvil + web/PWA). |
| **Riverpod** (`flutter_riverpod`) | Gestión de estado e inyección de dependencias. |
| **go_router** | Navegación declarativa y guard de sesión. |
| **Dio** | Cliente HTTP (listo para el backend; hoy inactivo con mocks). |
| **flutter_secure_storage** | Guardado seguro del token de sesión. |
| **qr_flutter** | Render del código QR del boleto. |

---

## 5. Cómo se conectará el backend (sin romper la metodología)

Hoy todo funciona con **repositorios mock en memoria**. Para pasar a un
backend real, por cada feature:

1. Crear en `data/` una clase `ApiXxxRepository implements XxxRepository`
   que use `Dio` (el cliente ya está en `core/network/api_client.dart`).
2. Cambiar **una línea** en el provider correspondiente
   (`xxxRepositoryProvider`) para que devuelva la implementación de API en
   lugar del mock.

No se toca la UI ni los controladores: ese es el objetivo de usar Repository
+ inyección de dependencias.

---

## 6. Convenciones de código

- **Idioma**: dominio y nombres de negocio en español; APIs de Flutter en
  inglés (como es estándar).
- **Lint** (ver `analysis_options.yaml`): comillas simples,
  `const` donde aplica, `final` para locales, comas finales obligatorias,
  prohibido `print`.
- **Inmutabilidad**: los modelos no se mutan; se usa `copyWith`.
- **Verificación antes de subir**: `flutter analyze` sin issues y
  `flutter test` en verde (incluye pruebas de lógica, de flujo y de
  accesibilidad).

---

## 7. Trazabilidad a las Historias de Usuario

Cada feature corresponde a una épica del DFR:

| Feature | Épica | Historias |
|---|---|---|
| `auth` | 1 — Autenticación | HU-01 a HU-04 |
| `catalog` | 2 — Publicaciones | HU-05 a HU-12 |
| `rentals` | 3 — Pagos y QR | HU-13 a HU-17 |
| `reception` | 4 — Recepción | HU-18 a HU-21 |
| `admin` | 5 — Admin e Incidencias | HU-22 a HU-27 |
