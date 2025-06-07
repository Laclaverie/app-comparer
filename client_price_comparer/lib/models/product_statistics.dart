import 'package:json_annotation/json_annotation.dart';
import 'store_price.dart';

part 'product_statistics.g.dart';

/// Contains comprehensive statistical analysis of product prices across multiple stores
/// Provides essential metrics like averages, variance, and price volatility indicators
/// Used for market analysis, price trend detection, and helping users understand deal quality
@JsonSerializable()
class ProductStatistics {
  @JsonKey(name: 'average_price')
  final double averagePrice;
  
  @JsonKey(name: 'median_price')
  final double medianPrice;
  
  @JsonKey(name: 'min_price')
  final double minPrice;
  
  @JsonKey(name: 'max_price')
  final double maxPrice;
  
  @JsonKey(name: 'price_variance')
  final double priceVariance;
  
  @JsonKey(name: 'standard_deviation')
  final double standardDeviation;
  
  @JsonKey(name: 'best_deal')
  final StorePrice bestDeal;
  
  @JsonKey(name: 'worst_deal')
  final StorePrice worstDeal;
  
  @JsonKey(name: 'all_prices')
  final List<StorePrice> allPrices;
  
  @JsonKey(name: 'calculated_at')
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

  factory ProductStatistics.fromJson(Map<String, dynamic> json) => _$ProductStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductStatisticsToJson(this);
}