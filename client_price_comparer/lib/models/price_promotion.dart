import 'package:json_annotation/json_annotation.dart';
import 'promotion_type.dart';

part 'price_promotion.g.dart';

/// Represents a promotional offer applied to a product price
/// Contains promotion details, validity periods, and parameters for different discount types
/// Used to calculate effective prices and display promotional information to users
@JsonSerializable()
class PricePromotion {
  final PromotionType type;
  final String description;
  final Map<String, dynamic> parameters;
  
  @JsonKey(name: 'valid_from')
  final DateTime? validFrom;
  
  @JsonKey(name: 'valid_to')
  final DateTime? validTo;

  PricePromotion({
    required this.type,
    required this.description,
    required this.parameters,
    this.validFrom,
    this.validTo,
  });

  factory PricePromotion.fromJson(Map<String, dynamic> json) => _$PricePromotionFromJson(json);
  Map<String, dynamic> toJson() => _$PricePromotionToJson(this);
}