import 'package:json_annotation/json_annotation.dart';
import 'price_promotion.dart';

part 'price_point.g.dart';

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
    if (promotion == null || !promotion!.isValid) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  /// Check if this price point has an active promotion
  bool get hasActivePromotion {
    return promotion != null && promotion!.isValid;
  }

  /// Get savings amount compared to regular price
  double get savingsAmount {
    return price - effectivePrice;
  }

  /// Get savings percentage compared to regular price
  double get savingsPercentage {
    if (price == 0) return 0;
    return (savingsAmount / price) * 100;
  }

  /// Get formatted price string
  String get formattedPrice {
    return '€${effectivePrice.toStringAsFixed(2)}';
  }

  /// Get formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get price description including store and promotion info
  String get priceDescription {
    if (!hasActivePromotion) {
      return '€${price.toStringAsFixed(2)}${storeName != null ? ' at $storeName' : ''}';
    }
    
    return '€${effectivePrice.toStringAsFixed(2)} (was €${price.toStringAsFixed(2)})${storeName != null ? ' at $storeName' : ''}';
  }

  /// Check if this price is higher than another price point
  bool isHigherThan(PricePoint other) {
    return effectivePrice > other.effectivePrice;
  }

  /// Check if this price is lower than another price point
  bool isLowerThan(PricePoint other) {
    return effectivePrice < other.effectivePrice;
  }

  /// Get the price difference compared to another price point
  double priceDifference(PricePoint other) {
    return effectivePrice - other.effectivePrice;
  }

  factory PricePoint.fromJson(Map<String, dynamic> json) => _$PricePointFromJson(json);
  Map<String, dynamic> toJson() => _$PricePointToJson(this);
}