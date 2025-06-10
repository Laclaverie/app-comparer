import '../models/price/price_promotion.dart';
import '../models/promotion/promotion_type.dart';

/// Handles all promotion-related calculations and validation logic
/// Provides methods to calculate effective prices, validate promotion periods,
/// and determine minimum quantities required for promotional deals
class PromotionCalculator {
  static double calculateEffectivePrice(PricePromotion promotion, double basePrice) {
    switch (promotion.type) {
      case PromotionType.percentageDiscount:
        final discount = promotion.parameters['percentage'] as double;
        return basePrice * (1 - discount / 100);
        
      case PromotionType.fixedDiscount:
        final discount = promotion.parameters['amount'] as double;
        return (basePrice - discount).clamp(0, double.infinity);
        
      case PromotionType.buyXGetY:
        final buyQuantity = promotion.parameters['buyQuantity'] as int;
        final getQuantity = promotion.parameters['getQuantity'] as int;
        final totalUnits = buyQuantity + getQuantity;
        return basePrice * buyQuantity / totalUnits;
        
      case PromotionType.buyXForY:
        final quantity = promotion.parameters['quantity'] as int;
        final totalPrice = promotion.parameters['totalPrice'] as double;
        return totalPrice / quantity;
        
      case PromotionType.multipleQuantity:
        final quantity = promotion.parameters['quantity'] as int;
        final totalPrice = promotion.parameters['totalPrice'] as double;
        return totalPrice / quantity;
    }
  }

  static bool isPromotionValid(PricePromotion promotion) {
    final now = DateTime.now();
    if (promotion.validFrom != null && now.isBefore(promotion.validFrom!)) return false;
    if (promotion.validTo != null && now.isAfter(promotion.validTo!)) return false;
    return true;
  }

  static int getMinimumQuantity(PricePromotion promotion) {
    switch (promotion.type) {
      case PromotionType.percentageDiscount:
      case PromotionType.fixedDiscount:
        return 1;
        
      case PromotionType.buyXGetY:
        return promotion.parameters['buyQuantity'] as int;
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        return promotion.parameters['quantity'] as int;
    }
  }

  static double getSavingsPercentage(PricePromotion promotion, double basePrice) {
    final effectivePrice = calculateEffectivePrice(promotion, basePrice);
    return ((basePrice - effectivePrice) / basePrice) * 100;
  }
}