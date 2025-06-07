import 'price_promotion.dart';

/// Represents a historical price data point at a specific date and store
/// Used for tracking price changes over time and building price history charts
/// Contains timestamp, price value, store information, and any active promotions
class PricePoint {
  final DateTime date;
  final double price;
  final String? storeName;
  final PricePromotion? promotion;

  PricePoint({
    required this.date,
    required this.price,
    this.storeName,
    this.promotion,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: DateTime.parse(json['date']),
      price: json['price'].toDouble(),
      storeName: json['storeName'],
      promotion: json['promotion'] != null 
          ? PricePromotion.fromJson(json['promotion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'price': price,
      'storeName': storeName,
      'promotion': promotion?.toJson(),
    };
  }
}