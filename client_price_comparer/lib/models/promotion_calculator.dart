import '../models/price_promotion.dart';
import '../models/promotion_type.dart';

/// Handles all promotion-related calculations and validation logic
/// Provides methods to calculate effective prices, validate promotion periods,
/// and determine minimum quantities required for promotional deals
class PromotionCalculator {
  static double calculateEffectivePrice(PricePromotion promotion, double basePrice) {
    // Validate parameters first
    if (!promotion.hasValidParameters) {
      throw ArgumentError('Invalid promotion parameters: ${promotion.parameterValidationError}');
    }
    
    switch (promotion.type) {
      case PromotionType.percentageDiscount:
        final discount = promotion.percentage!;
        return basePrice * (1 - discount / 100);
        
      case PromotionType.fixedDiscount:
        final discount = promotion.discountAmount!;
        return (basePrice - discount).clamp(0, double.infinity);
        
      case PromotionType.buyXGetY:
        final buyQty = promotion.buyQuantity!;
        final getQty = promotion.getQuantity!;
        final totalUnits = buyQty + getQty;
        return basePrice * buyQty / totalUnits;
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        final quantity = promotion.bundleQuantity!;
        final totalPrice = promotion.totalPrice!;
        return totalPrice / quantity;
    }
  }

  static int getMinimumQuantity(PricePromotion promotion) {
    if (!promotion.hasValidParameters) return 1;
    
    switch (promotion.type) {
      case PromotionType.percentageDiscount:
      case PromotionType.fixedDiscount:
        return 1;
        
      case PromotionType.buyXGetY:
        return promotion.buyQuantity ?? 1;
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        return promotion.bundleQuantity ?? 1;
    }
  }

  static bool isPromotionValid(PricePromotion promotion) {
    final now = DateTime.now();
    if (promotion.validFrom != null && now.isBefore(promotion.validFrom!)) return false;
    if (promotion.validTo != null && now.isAfter(promotion.validTo!)) return false;
    return promotion.hasValidParameters;
  }

  static double getSavingsPercentage(PricePromotion promotion, double basePrice) {
    final effectivePrice = calculateEffectivePrice(promotion, basePrice);
    return ((basePrice - effectivePrice) / basePrice) * 100;
  }
}