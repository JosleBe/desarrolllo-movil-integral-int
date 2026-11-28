import 'earnings_period.dart';

/// Desglose de ingresos por publicación/artículo (HU-37).
class ListingEarnings {
  const ListingEarnings({
    required this.listingId,
    required this.listingTitle,
    required this.totalAmount,
    required this.completedRentalsCount,
  });

  final String listingId;
  final String listingTitle;
  final double totalAmount;
  final int completedRentalsCount;
}

/// Punto de datos temporal para la gráfica de ingresos (HU-37).
class EarningsDataPoint {
  const EarningsDataPoint({
    required this.label,
    required this.amount,
    required this.date,
  });

  final String label;
  final double amount;
  final DateTime date;
}

/// Modelo de datos agregados de ingresos del Vendedor (HU-37).
class SellerEarnings {
  const SellerEarnings({
    required this.ownerId,
    required this.period,
    required this.totalEarnings,
    required this.totalRentalsCount,
    required this.byListing,
    required this.chartPoints,
    this.selectedListingId,
  });

  final String ownerId;
  final EarningsPeriod period;
  final double totalEarnings;
  final int totalRentalsCount;
  final List<ListingEarnings> byListing;
  final List<EarningsDataPoint> chartPoints;
  final String? selectedListingId;

  bool get isEmpty => totalEarnings == 0 && totalRentalsCount == 0;
}
