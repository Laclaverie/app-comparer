import 'package:json_annotation/json_annotation.dart';

part 'price_historydto.g.dart';

@JsonSerializable()
class PriceHistoryDto {
  final int? id;
  final int productId;
  final int supermarketId;
  final double price;
  final double? originalPrice;
  final DateTime date;
  final bool isPromotion;
  final String? promotionDescription;
  final String? storeName;
  final String? storeLocation;
  final bool isCurrentStore;
  final PromotionDto? promotion;

  const PriceHistoryDto({
    this.id,
    required this.productId,
    required this.supermarketId,
    required this.price,
    this.originalPrice,
    required this.date,
    this.isPromotion = false,
    this.promotionDescription,
    this.storeName,
    this.storeLocation,
    this.isCurrentStore = false,
    this.promotion,
  });

  factory PriceHistoryDto.fromJson(Map<String, dynamic> json) => 
      _$PriceHistoryDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$PriceHistoryDtoToJson(this);
}

@JsonSerializable()
class PromotionDto {
  final String description;
  final double? discount;

  const PromotionDto({
    required this.description,
    this.discount,
  });

  factory PromotionDto.fromJson(Map<String, dynamic> json) => 
      _$PromotionDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$PromotionDtoToJson(this);
}