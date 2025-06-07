import 'store_price.dart';

class ProductStatistics {
  final double averagePrice;
  final double medianPrice;
  final double minPrice;
  final double maxPrice;
  final double priceVariance;
  final double standardDeviation;
  final StorePrice bestDeal;
  final StorePrice worstDeal;
  final List<StorePrice> allPrices;
  final DateTime calculatedAt;

  ProductStatistics({
    required this.averagePrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceVariance,
    required this.standardDeviation,
    required this.bestDeal,
    required this.worstDeal,
    required this.allPrices,
    required this.calculatedAt,
  });

  /// Get price spread (difference between min and max)
  double get priceSpread => maxPrice - minPrice;

  /// Get price spread percentage
  double get priceSpreadPercentage => (priceSpread / minPrice) * 100;

  /// Check if prices are volatile (high variance relative to mean)
  bool get isVolatile => standardDeviation > (averagePrice * 0.2);

  /// Get coefficient of variation (standardDeviation / mean)
  double get coefficientOfVariation => standardDeviation / averagePrice;
}