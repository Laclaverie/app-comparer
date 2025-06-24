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
  
  /// Original catalog price before any promotions
  final double price;
  
  @JsonKey(name: 'is_current_store', defaultValue: false)
  final bool isCurrentStore;
  
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;
  
  @JsonKey(includeIfNull: false)
  final PricePromotion? promotion;

  @JsonKey(name: 'store_id', includeIfNull: false)
  final int? storeId;

  StorePrice({
    required this.storeName,
    required this.price,
    required this.isCurrentStore,
    required this.lastUpdated,
    this.promotion,
    this.storeId,
  });

  /// Get the effective price considering promotions
  double get effectivePrice {
    if (promotion == null || !promotion!.isValid) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  /// Check if this store price has an active promotion
  bool get hasActivePromotion {
    return promotion != null && promotion!.isValid;
  }

  /// Get promotion description or null if no promotion
  String? get promotionDescription {
    if (!hasActivePromotion) return null;
    return promotion!.description;
  }

  /// ✅ CORRECTION : Getter au lieu de duplication de logique
  double get priceWithPromotionApplied => effectivePrice;

  /// ✅ NOUVEAU : Prix original pour base de données (clarté)
  double get originalPrice => promotion?.originalPrice ?? price;

  factory StorePrice.fromJson(Map<String, dynamic> json) => _$StorePriceFromJson(json);
  Map<String, dynamic> toJson() => _$StorePriceToJson(this);
}