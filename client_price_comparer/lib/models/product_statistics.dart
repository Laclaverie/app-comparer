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

  /// Get explanation for the best deal
  String get bestDealExplanation {
    if (bestDeal.promotion == null || !bestDeal.promotion!.isValid) {
      return 'Regular price: €${bestDeal.price.toStringAsFixed(2)} at ${bestDeal.storeName}';
    }
    
    return '${bestDeal.promotion!.getPromotionExplanation(bestDeal.price)} at ${bestDeal.storeName}';
  }

  /// Get explanation for the worst deal
  String get worstDealExplanation {
    if (worstDeal.promotion == null || !worstDeal.promotion!.isValid) {
      return 'Regular price: €${worstDeal.price.toStringAsFixed(2)} at ${worstDeal.storeName}';
    }
    
    return 'Even with promotion (${worstDeal.promotion!.description}): €${worstDeal.effectivePrice.toStringAsFixed(2)} at ${worstDeal.storeName}';
  }

  /// Get market analysis summary
  String get marketAnalysisSummary {
    if (isVolatile) {
      return 'High price variation detected (${priceSpreadPercentage.toStringAsFixed(1)}% spread)';
    } else {
      return 'Stable pricing across stores (${priceSpreadPercentage.toStringAsFixed(1)}% spread)';
    }
  }

  /// Get deal quality assessment
  String get dealQuality {
    final savingsVsAverage = ((averagePrice - bestDeal.effectivePrice) / averagePrice) * 100;
    
    if (savingsVsAverage > 20) {
      return 'Excellent deal - ${savingsVsAverage.toStringAsFixed(1)}% below average';
    } else if (savingsVsAverage > 10) {
      return 'Good deal - ${savingsVsAverage.toStringAsFixed(1)}% below average';
    } else if (savingsVsAverage > 0) {
      return 'Fair deal - ${savingsVsAverage.toStringAsFixed(1)}% below average';
    } else {
      return 'Above average price';
    }
  }

  factory ProductStatistics.fromJson(Map<String, dynamic> json) => _$ProductStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductStatisticsToJson(this);
}