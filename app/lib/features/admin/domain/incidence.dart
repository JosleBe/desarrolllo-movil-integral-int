/// Tipo de incidencia que se puede reportar (HU-22).
enum IncidenceType {
  damage('Daño'),
  delay('Demora'),
  missing('Artículo faltante'),
  notDelivered('No entregado');

  const IncidenceType(this.label);
  final String label;
}

/// Estado de una incidencia (HU-23).
enum IncidenceStatus {
  open('Abierta'),
  resolved('Resuelta');

  const IncidenceStatus(this.label);
  final String label;
}

/// Reporte de incidencia sobre una renta (HU-22, HU-23).
///
/// Lo puede crear Vendedor, Rentador o Recepción; lo resuelve el
/// Administrador. Al crearse, la renta asociada pasa a estado INCIDENCIA.
class Incidence {
  const Incidence({
    required this.id,
    required this.rentalId,
    required this.rentalTitle,
    required this.type,
    required this.description,
    required this.reportedBy,
    required this.createdAt,
    this.status = IncidenceStatus.open,
    this.resolution,
    this.resolvedAt,
  });

  final String id;
  final String rentalId;
  final String rentalTitle;
  final IncidenceType type;
  final String description;

  /// Nombre de quien reportó la incidencia.
  final String reportedBy;

  final DateTime createdAt;
  final IncidenceStatus status;

  /// Texto de la resolución del Administrador (HU-23).
  final String? resolution;
  final DateTime? resolvedAt;

  bool get isOpen => status == IncidenceStatus.open;

  Incidence copyWith({
    IncidenceStatus? status,
    String? resolution,
    DateTime? resolvedAt,
  }) {
    return Incidence(
      id: id,
      rentalId: rentalId,
      rentalTitle: rentalTitle,
      type: type,
      description: description,
      reportedBy: reportedBy,
      createdAt: createdAt,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
