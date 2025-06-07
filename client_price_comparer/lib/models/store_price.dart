import 'package:json_annotation/json_annotation.dart';
import 'price_promotion.dart';

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

  factory StorePrice.fromJson(Map<String, dynamic> json) => _$StorePriceFromJson(json);
  Map<String, dynamic> toJson() => _$StorePriceToJson(this);
}