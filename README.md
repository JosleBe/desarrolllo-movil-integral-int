# Épica 2: Catálogo y Publicaciones — Código de Josué

Este documento especifica la ubicación y estructura de todos los archivos que corresponden a la parte de **Josué** (Épica 2: Catálogo y Publicaciones, Historias de Usuario HU-05 a HU-12).

---

## 📂 Archivos del Código de Josué

El código está organizado siguiendo la arquitectura *Feature-First* en la ruta `app/lib/features/catalog/` y sus pruebas en `app/test/catalog/`:

### 1. Dominio (`app/lib/features/catalog/domain/`)
- [`catalog_enums.dart`](app/lib/features/catalog/domain/catalog_enums.dart): Enums de categorías, estado físico del artículo, periodos de renta (`RentalPeriod`), estado de publicación y `PriceOption`.
- [`catalog_filters.dart`](app/lib/features/catalog/domain/catalog_filters.dart): Modelo de filtros combinables para la búsqueda avanzada (`CatalogFilters`).
- [`listing.dart`](app/lib/features/catalog/domain/listing.dart): Entidad principal de la publicación/artículo (`Listing`).
- [`listing_repository.dart`](app/lib/features/catalog/domain/listing_repository.dart): Contrato e interfaz abstracta del repositorio de catálogo (`ListingRepository`), excepciones de dominio (`NotListingOwner`, `ListingHasActiveRentals`) y `ListingDraft`.

### 2. Datos (`app/lib/features/catalog/data/`)
- [`mock_listing_repository.dart`](app/lib/features/catalog/data/mock_listing_repository.dart): Implementación en memoria (`MockListingRepository`) con datos semilla para desarrollo sin backend.

### 3. Presentación (`app/lib/features/catalog/presentation/`)
- [`catalog_page.dart`](app/lib/features/catalog/presentation/catalog_page.dart): Pantalla principal del catálogo con barra de búsqueda y filtros combinables (HU-05, HU-06, HU-10).
- [`listing_detail_page.dart`](app/lib/features/catalog/presentation/listing_detail_page.dart): Vista de detalle de publicación con precios por periodo y estado de disponibilidad (HU-07, HU-08, HU-09, HU-11).
- [`listing_form_page.dart`](app/lib/features/catalog/presentation/listing_form_page.dart): Formulario para publicar (HU-06) y editar (HU-07) artículos con precios por periodo (HU-08) y galería (HU-09).
- [`my_listings_page.dart`](app/lib/features/catalog/presentation/my_listings_page.dart): Panel del vendedor "Mis publicaciones" para pausar, reactivar, editar y eliminar publicaciones (HU-07, HU-12).
- [`price_format.dart`](app/lib/features/catalog/presentation/price_format.dart): Utilidad de formato monetario y periodos.

#### Proveedores Riverpod (`presentation/providers/`)
- [`catalog_providers.dart`](app/lib/features/catalog/presentation/providers/catalog_providers.dart): Proveedores `listingRepositoryProvider`, `catalogFiltersProvider`, `catalogResultsProvider`, `listingDetailProvider` y `myListingsProvider`.
- [`listing_actions.dart`](app/lib/features/catalog/presentation/providers/listing_actions.dart): Acciones de mutación para crear, editar, pausar y eliminar publicaciones.

#### Widgets Reutilizables (`presentation/widgets/`)
- [`listing_card.dart`](app/lib/features/catalog/presentation/widgets/listing_card.dart): Tarjeta visual del artículo con insignia de disponibilidad.
- [`listing_gallery.dart`](app/lib/features/catalog/presentation/widgets/listing_gallery.dart): Galería de imágenes deslizable con vista previa fallback.

### 4. Archivo de Exportación Directa
- [`catalog.dart`](app/lib/features/catalog/catalog.dart): Exporta de forma centralizada todas las entidades, vistas y proveedores del catálogo para facilitar la importación desde otros módulos.

### 5. Pruebas Unitarias (`app/test/catalog/`)
- [`listing_test.dart`](app/test/catalog/listing_test.dart): Pruebas del modelo de dominio `Listing`.
- [`mock_listing_repository_test.dart`](app/test/catalog/mock_listing_repository_test.dart): Pruebas del repositorio `MockListingRepository` (filtros combinables, creación, edición, pausado y eliminación).

---

## 🛠️ Cómo Integrar con el Resto de Partes

Para integrar el módulo de Josué con las características de los demás integrantes:

1. **Importación simple:** Importar `package:sruu/features/catalog/catalog.dart`.
2. **Navegación / Rutas:** Registrar `CatalogPage()`, `MyListingsPage()`, `ListingFormPage()` y `ListingDetailPage(id)` en `AppRouter`.
3. **Flujo de Renta (Épica 3 - Apaez):** En `listing_detail_page.dart`, al presionar *Solicitar renta*, redirigir a `RentRequestPage(listing: listing)`.
