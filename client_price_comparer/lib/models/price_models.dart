import 'package:json_annotation/json_annotation.dart';
import 'price_promotion.dart';
import 'store_price.dart';

part 'price_models.g.dart';

/// Represents a historical price data point at a specific date and store
/// Used for tracking price changes over time and building price history charts
/// Contains timestamp, price value, store information, and any active promotions
@JsonSerializable()
class PricePoint {
  final DateTime date;
  final double price;
  
  @JsonKey(name: 'store_name', includeIfNull: false)
  final String? storeName;
  
  @JsonKey(includeIfNull: false)
  final PricePromotion? promotion;

  PricePoint({
    required this.date,
    required this.price,
    this.storeName,
    this.promotion,
  });

  /// Get the effective price considering promotions
  double get effectivePrice {
    if (promotion == null) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  factory PricePoint.fromJson(Map<String, dynamic> json) => _$PricePointFromJson(json);
  Map<String, dynamic> toJson() => _$PricePointToJson(this);
}

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
  
  @JsonKey(name: 'best_deal')
  final StorePrice bestDeal;
  
  @JsonKey(name: 'worst_deal')
  final StorePrice worstDeal;

  ProductStatistics({
    required this.averagePrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceVariance,
    required this.bestDeal,
    required this.worstDeal,
  });

  /// Get price spread (difference between min and max)
  double get priceSpread => maxPrice - minPrice;

  /// Get price spread percentage
  double get priceSpreadPercentage => (priceSpread / minPrice) * 100;

  String get bestDealExplanation {
    if (bestDeal.promotion == null || !bestDeal.promotion!.isValid) {
      return 'Regular price: €${bestDeal.price.toStringAsFixed(2)} at ${bestDeal.storeName}';
    }
    
    return '${bestDeal.promotion!.getPromotionExplanation(bestDeal.price)} at ${bestDeal.storeName}';
  }

  String get worstDealExplanation {
    if (worstDeal.promotion == null || !worstDeal.promotion!.isValid) {
      return 'Regular price: €${worstDeal.price.toStringAsFixed(2)} at ${worstDeal.storeName}';
    }
    
    return 'Even with promotion (${worstDeal.promotion!.description}): €${worstDeal.effectivePrice.toStringAsFixed(2)} at ${worstDeal.storeName}';
  }

  factory ProductStatistics.fromJson(Map<String, dynamic> json) => _$ProductStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductStatisticsToJson(this);
}

/// Defines display modes for product information in the user interface
/// Controls the level of detail shown to users based on their preferences
enum ProductDisplayMode {
  @JsonValue('minimal')
  minimal,
  
  @JsonValue('advanced')
  advanced,
}