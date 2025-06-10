import 'package:flutter_test/flutter_test.dart';
import 'package:client_price_comparer/models/price/price_promotion.dart';
import 'package:client_price_comparer/models/promotion/promotion_type.dart';

void main() {
  group('PricePromotion', () {
    group('Factory Constructors', () {
      test('should create percentage discount promotion', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        expect(promotion.type, PromotionType.percentageDiscount);
        expect(promotion.description, '20% off');
        expect(promotion.percentage, 20.0);
        expect(promotion.hasValidParameters, true);
      });

      test('should create fixed discount promotion', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€2 off',
          amount: 2.0,
        );

        expect(promotion.type, PromotionType.fixedDiscount);
        expect(promotion.description, '€2 off');
        expect(promotion.discountAmount, 2.0);
        expect(promotion.hasValidParameters, true);
      });

      test('should create buy X get Y promotion', () {
        final promotion = PricePromotion.buyXGetY(
          description: 'Buy 3 get 1 free',
          buyQuantity: 3,
          getQuantity: 1,
        );

        expect(promotion.type, PromotionType.buyXGetY);
        expect(promotion.description, 'Buy 3 get 1 free');
        expect(promotion.buyQuantity, 3);
        expect(promotion.getQuantity, 1);
        expect(promotion.hasValidParameters, true);
      });

      test('should create buy X for Y promotion', () {
        final promotion = PricePromotion.buyXForY(
          description: '2 for €5',
          quantity: 2,
          totalPrice: 5.0,
        );

        expect(promotion.type, PromotionType.buyXForY);
        expect(promotion.description, '2 for €5');
        expect(promotion.bundleQuantity, 2);
        expect(promotion.totalPrice, 5.0);
        expect(promotion.hasValidParameters, true);
      });
    });

    group('Validation', () {
      test('should reject invalid percentage', () {
        expect(
          () => PricePromotion.percentageDiscount(
            description: 'Invalid discount',
            percentage: -10.0,
          ),
          throwsArgumentError,
        );

        expect(
          () => PricePromotion.percentageDiscount(
            description: 'Invalid discount',
            percentage: 150.0,
          ),
          throwsArgumentError,
        );
      });

      test('should reject negative discount amount', () {
        expect(
          () => PricePromotion.fixedDiscount(
            description: 'Invalid discount',
            amount: -5.0,
          ),
          throwsArgumentError,
        );
      });

      test('should reject invalid quantities', () {
        expect(
          () => PricePromotion.buyXGetY(
            description: 'Invalid promotion',
            buyQuantity: 0,
            getQuantity: 1,
          ),
          throwsArgumentError,
        );

        expect(
          () => PricePromotion.buyXForY(
            description: 'Invalid bundle',
            quantity: -1,
            totalPrice: 10.0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Type-Safe Getters', () {
      test('should return null for wrong promotion type', () {
        final percentagePromo = PricePromotion.percentageDiscount(
          description: '10% off',
          percentage: 10.0,
        );

        // Should return null when accessing other type's parameters
        expect(percentagePromo.discountAmount, null);
        expect(percentagePromo.buyQuantity, null);
        expect(percentagePromo.getQuantity, null);
        expect(percentagePromo.bundleQuantity, null);
        expect(percentagePromo.totalPrice, null);
      });

      test('should return correct values for right promotion type', () {
        final buyGetPromo = PricePromotion.buyXGetY(
          description: 'Buy 2 get 1 free',
          buyQuantity: 2,
          getQuantity: 1,
        );

        expect(buyGetPromo.buyQuantity, 2);
        expect(buyGetPromo.getQuantity, 1);
        expect(buyGetPromo.percentage, null);
        expect(buyGetPromo.discountAmount, null);
      });
    });

    group('Parameter Validation', () {
      test('should detect valid parameters', () {
        final validPromo = PricePromotion.percentageDiscount(
          description: '15% off',
          percentage: 15.0,
        );

        expect(validPromo.hasValidParameters, true);
        expect(validPromo.parameterValidationError, null);
      });

      test('should detect invalid parameters', () {
        // Create promotion with missing parameters
        final invalidPromo = PricePromotion(
          type: PromotionType.percentageDiscount,
          description: 'Broken promotion',
          parameters: {}, // Empty parameters
        );

        expect(invalidPromo.hasValidParameters, false);
        expect(invalidPromo.parameterValidationError, isNotNull);
        expect(
          invalidPromo.parameterValidationError,
          contains('percentage'),
        );
      });

      test('should detect wrong parameter types', () {
        final wrongTypePromo = PricePromotion(
          type: PromotionType.percentageDiscount,
          description: 'Wrong type',
          parameters: {'percentage': 'not_a_number'}, // String instead of number
        );

        expect(wrongTypePromo.hasValidParameters, false);
        expect(wrongTypePromo.percentage, null);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '25% off',
          percentage: 25.0,
          validFrom: DateTime(2024, 1, 1),
          validTo: DateTime(2024, 12, 31),
        );

        final json = promotion.toJson();

        expect(json['type'], 'percentage_discount');
        expect(json['description'], '25% off');
        expect(json['parameters']['percentage'], 25.0);
        expect(json['valid_from'], '2024-01-01T00:00:00.000');
        expect(json['valid_to'], '2024-12-31T00:00:00.000');
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'type': 'buy_x_get_y',
          'description': 'Buy 3 get 2 free',
          'parameters': {
            'buyQuantity': 3,
            'getQuantity': 2,
          },
          'valid_from': '2024-06-01T00:00:00.000',
          'valid_to': '2024-06-30T23:59:59.000',
        };

        final promotion = PricePromotion.fromJson(json);

        expect(promotion.type, PromotionType.buyXGetY);
        expect(promotion.description, 'Buy 3 get 2 free');
        expect(promotion.buyQuantity, 3);
        expect(promotion.getQuantity, 2);
        expect(promotion.validFrom, DateTime(2024, 6, 1));
        expect(promotion.validTo, DateTime(2024, 6, 30, 23, 59, 59));
      });

      test('should handle null dates in JSON', () {
        final json = {
          'type': 'fixed_discount',
          'description': '€5 off',
          'parameters': {
            'amount': 5.0,
          },
        };

        final promotion = PricePromotion.fromJson(json);

        expect(promotion.validFrom, null);
        expect(promotion.validTo, null);
        expect(promotion.discountAmount, 5.0);
      });
    });

    group('Edge Cases', () {
      test('should handle zero percentage', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '0% off (no discount)',
          percentage: 0.0,
        );

        expect(promotion.percentage, 0.0);
        expect(promotion.hasValidParameters, true);
      });

      test('should handle 100% discount', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '100% off (free)',
          percentage: 100.0,
        );

        expect(promotion.percentage, 100.0);
        expect(promotion.hasValidParameters, true);
      });

      test('should handle very small amounts', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€0.01 off',
          amount: 0.01,
        );

        expect(promotion.discountAmount, 0.01);
        expect(promotion.hasValidParameters, true);
      });
    });

    group('Real-World Scenarios', () {
      test('should create typical grocery store promotions', () {
        // Common supermarket promotions
        final promotions = [
          PricePromotion.percentageDiscount(
            description: '20% off all dairy products',
            percentage: 20.0,
            validTo: DateTime.now().add(const Duration(days: 7)),
          ),
          PricePromotion.buyXGetY(
            description: 'Buy 2 yogurts, get 1 free',
            buyQuantity: 2,
            getQuantity: 1,
          ),
          PricePromotion.buyXForY(
            description: '3 bottles of water for €2',
            quantity: 3,
            totalPrice: 2.0,
          ),
          PricePromotion.fixedDiscount(
            description: '€1 off when you spend €10+',
            amount: 1.0,
          ),
        ];

        for (final promo in promotions) {
          expect(promo.hasValidParameters, true);
          expect(promo.parameterValidationError, null);
        }
      });
    });
  });
}