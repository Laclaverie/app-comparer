import 'price_promotion.dart';

class StorePrice {
  final String storeName;
  final double price;
  final bool isCurrentStore;
  final DateTime lastUpdated;
  final PricePromotion? promotion;

  StorePrice({
    required this.storeName,
    required this.price,
    required this.isCurrentStore,
    required this.lastUpdated,
    this.promotion,
  });

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    return StorePrice(
      storeName: json['storeName'],
      price: json['price'].toDouble(),
      isCurrentStore: json['isCurrentStore'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      promotion: json['promotion'] != null 
          ? PricePromotion.fromJson(json['promotion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'price': price,
      'isCurrentStore': isCurrentStore,
      'lastUpdated': lastUpdated.toIso8601String(),
      'promotion': promotion?.toJson(),
    };
  }
}