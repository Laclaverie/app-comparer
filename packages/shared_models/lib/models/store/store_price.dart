import 'package:json_annotation/json_annotation.dart';
import '../price/price_promotion.dart';

part 'store_price.g.dart';

/// Represents a product price at a specific store with promotion and timestamp information
/// Core data model for price comparison functionality across different retailers
/// Tracks current user's store preference and promotional offers
@JsonSerializable()
class StorePrice {
  @JsonKey(name: 'store_name')
  final String storeName;
  
  final double price;
  
  @JsonKey(name: 'is_current_store', defaultValue: false)
  final bool isCurrentStore;
  
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;
  
  @JsonKey(includeIfNull: false)
  final PricePromotion? promotion;

  StorePrice({
    required this.storeName,
    required this.price,
    required this.isCurrentStore,
    required this.lastUpdated,
    this.promotion,
  });

  /// Get the effective price considering promotions
  double get effectivePrice {
    if (promotion == null || !promotion!.isValid) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  /// Get the best deal description including promotion details
  String get dealDescription {
    if (promotion == null || !promotion!.isValid) {
      return '€${price.toStringAsFixed(2)} at $storeName';
    }
    
    return '€${effectivePrice.toStringAsFixed(2)} at $storeName (${promotion!.description})';
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

  /// Check if this store price has an active promotion
  bool get hasActivePromotion {
    return promotion != null && promotion!.isValid;
  }

  /// Get promotion description or empty string if no promotion
  String get promotionDescription {
    if (!hasActivePromotion) return '';
    return promotion!.description;
  }

  /// Get detailed price breakdown including promotion info
  String get priceBreakdown {
    if (!hasActivePromotion) {
      return 'Regular price: €${price.toStringAsFixed(2)}';
    }
    
    final savings = savingsAmount;
    if (savings > 0) {
      return 'Original: €${price.toStringAsFixed(2)} → €${effectivePrice.toStringAsFixed(2)} (Save €${savings.toStringAsFixed(2)})';
    } else {
      return 'Special price: €${effectivePrice.toStringAsFixed(2)}';
    }
  }

  factory StorePrice.fromJson(Map<String, dynamic> json) => _$StorePriceFromJson(json);
  Map<String, dynamic> toJson() => _$StorePriceToJson(this);
}