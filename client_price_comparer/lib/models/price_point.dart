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

  factory PricePoint.fromJson(Map<String, dynamic> json) => _$PricePointFromJson(json);
  Map<String, dynamic> toJson() => _$PricePointToJson(this);
}