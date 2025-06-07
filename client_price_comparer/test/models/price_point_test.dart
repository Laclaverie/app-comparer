import 'package:test/test.dart';
import 'package:client_price_comparer/models/price_point.dart';
import 'package:client_price_comparer/models/price_promotion.dart';

void main() {
  group('PricePoint', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2025, 6, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates price point with required fields only', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
        );

        expect(pricePoint.date, equals(testDate));
        expect(pricePoint.price, equals(3.50));
        expect(pricePoint.storeName, isNull);
        expect(pricePoint.promotion, isNull);
      });

      test('creates price point with all fields', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          storeName: 'Carrefour',
          promotion: promotion,
        );

        expect(pricePoint.date, equals(testDate));
        expect(pricePoint.price, equals(4.00));
        expect(pricePoint.storeName, equals('Carrefour'));
        expect(pricePoint.promotion, equals(promotion));
      });
    });

    group('effectivePrice', () {
      test('returns regular price when no promotion', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
        );

        expect(pricePoint.effectivePrice, equals(3.50));
      });

      test('returns regular price when promotion is invalid', () {
        final expiredPromotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
          validFrom: DateTime(2025, 1, 1),
          validTo: DateTime(2025, 1, 31), // Expired
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: expiredPromotion,
        );

        expect(pricePoint.effectivePrice, equals(4.00));
      });

      test('calculates effective price with percentage discount', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 5.00,
          promotion: promotion,
        );

        expect(pricePoint.effectivePrice, equals(4.00));
      });

      test('calculates effective price with fixed discount', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€1.50 off',
          amount: 1.50,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: promotion,
        );

        expect(pricePoint.effectivePrice, equals(2.50));
      });

      test('calculates effective price with buy X get Y promotion', () {
        final promotion = PricePromotion.buyXGetY(
          description: 'Buy 2 get 3 total',
          buyQuantity: 2,
          getQuantity: 1,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 3.00,
          promotion: promotion,
        );

        // Buy 2, get 3 total = pay for 2, get 3 = 2/3 = 0.667 of original price
        expect(pricePoint.effectivePrice, closeTo(2.00, 0.01));
      });

      test('calculates effective price with bundle promotion', () {
        final promotion = PricePromotion.buyXForY(
          description: '3 for €10',
          quantity: 3,
          totalPrice: 10.00,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: promotion,
        );

        expect(pricePoint.effectivePrice, closeTo(3.33, 0.01));
      });
    });

    group('hasActivePromotion', () {
      test('returns false when no promotion', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
        );

        expect(pricePoint.hasActivePromotion, isFalse);
      });

      test('returns false when promotion is expired', () {
        final expiredPromotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
          validTo: DateTime(2025, 1, 31), // Expired
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: expiredPromotion,
        );

        expect(pricePoint.hasActivePromotion, isFalse);
      });

      test('returns true when promotion is valid', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: promotion,
        );

        expect(pricePoint.hasActivePromotion, isTrue);
      });
    });

    group('savingsAmount and savingsPercentage', () {
      test('returns zero savings when no promotion', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
        );

        expect(pricePoint.savingsAmount, equals(0.0));
        expect(pricePoint.savingsPercentage, equals(0.0));
      });

      test('calculates savings with percentage discount', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 5.00,
          promotion: promotion,
        );

        expect(pricePoint.savingsAmount, equals(1.00));
        expect(pricePoint.savingsPercentage, equals(20.0));
      });

      test('calculates savings with fixed discount', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€1.00 off',
          amount: 1.00,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          promotion: promotion,
        );

        expect(pricePoint.savingsAmount, equals(1.00));
        expect(pricePoint.savingsPercentage, equals(25.0));
      });

      test('handles zero price edge case', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 0.0,
        );

        expect(pricePoint.savingsPercentage, equals(0.0));
      });
    });

    group('Formatting Methods', () {
      test('formats price correctly', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.456,
        );

        expect(pricePoint.formattedPrice, equals('€3.46'));
      });

      test('formats price with promotion correctly', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '10% off',
          percentage: 10.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 3.00,
          promotion: promotion,
        );

        expect(pricePoint.formattedPrice, equals('€2.70'));
      });

      test('formats date correctly', () {
        final pricePoint = PricePoint(
          date: DateTime(2025, 12, 5),
          price: 3.50,
        );

        expect(pricePoint.formattedDate, equals('5/12/2025'));
      });

      test('formats single digit date correctly', () {
        final pricePoint = PricePoint(
          date: DateTime(2025, 1, 9),
          price: 3.50,
        );

        expect(pricePoint.formattedDate, equals('9/1/2025'));
      });
    });

    group('priceDescription', () {
      test('describes regular price without store', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
        );

        expect(pricePoint.priceDescription, equals('€3.50'));
      });

      test('describes regular price with store', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
          storeName: 'Carrefour',
        );

        expect(pricePoint.priceDescription, equals('€3.50 at Carrefour'));
      });

      test('describes promotional price without store', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 5.00,
          promotion: promotion,
        );

        expect(pricePoint.priceDescription, equals('€4.00 (was €5.00)'));
      });

      test('describes promotional price with store', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€1 off',
          amount: 1.00,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          storeName: 'Leclerc',
          promotion: promotion,
        );

        expect(pricePoint.priceDescription, equals('€3.00 (was €4.00) at Leclerc'));
      });
    });

    group('Comparison Methods', () {
      late PricePoint basePoint;
      late PricePoint higherPoint;
      late PricePoint lowerPoint;
      late PricePoint equalPoint;

      setUp(() {
        basePoint = PricePoint(date: testDate, price: 3.00);
        higherPoint = PricePoint(date: testDate, price: 4.00);
        lowerPoint = PricePoint(date: testDate, price: 2.00);
        equalPoint = PricePoint(date: testDate, price: 3.00);
      });

      test('isHigherThan compares effective prices correctly', () {
        expect(higherPoint.isHigherThan(basePoint), isTrue);
        expect(basePoint.isHigherThan(higherPoint), isFalse);
        expect(basePoint.isHigherThan(equalPoint), isFalse);
      });

      test('isLowerThan compares effective prices correctly', () {
        expect(lowerPoint.isLowerThan(basePoint), isTrue);
        expect(basePoint.isLowerThan(lowerPoint), isFalse);
        expect(basePoint.isLowerThan(equalPoint), isFalse);
      });

      test('priceDifference calculates correctly', () {
        expect(higherPoint.priceDifference(basePoint), equals(1.00));
        expect(basePoint.priceDifference(higherPoint), equals(-1.00));
        expect(lowerPoint.priceDifference(basePoint), equals(-1.00));
        expect(basePoint.priceDifference(equalPoint), equals(0.00));
      });

      test('comparison works with promotional prices', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '50% off',
          percentage: 50.0,
        );

        final promotionalPoint = PricePoint(
          date: testDate,
          price: 6.00, // €6 with 50% off = €3 effective
          promotion: promotion,
        );

        expect(promotionalPoint.isHigherThan(lowerPoint), isTrue); // €3 > €2
        expect(promotionalPoint.isLowerThan(higherPoint), isTrue); // €3 < €4
        expect(promotionalPoint.priceDifference(basePoint), equals(0.00)); // €3 - €3
      });
    });

    group('JSON Serialization', () {
      test('serializes to JSON correctly', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
          storeName: 'Carrefour',
        );

        final json = pricePoint.toJson();

        expect(json['date'], isNotNull);
        expect(json['price'], equals(3.50));
        expect(json['store_name'], equals('Carrefour'));
      });

      test('serializes with promotion to JSON correctly', () {
        final promotion = PricePromotion.percentageDiscount(
          description: '20% off',
          percentage: 20.0,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 4.00,
          storeName: 'Leclerc',
          promotion: promotion,
        );

        final json = pricePoint.toJson();

        expect(json['date'], isNotNull);
        expect(json['price'], equals(4.00));
        expect(json['store_name'], equals('Leclerc'));
        expect(json['promotion'], isNotNull);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'date': testDate.toIso8601String(),
          'price': 3.50,
          'store_name': 'Carrefour',
        };

        final pricePoint = PricePoint.fromJson(json);

        expect(pricePoint.date, equals(testDate));
        expect(pricePoint.price, equals(3.50));
        expect(pricePoint.storeName, equals('Carrefour'));
        expect(pricePoint.promotion, isNull);
      });
    });

    group('Edge Cases', () {
      test('handles very small prices', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 0.01,
        );

        expect(pricePoint.effectivePrice, equals(0.01));
        expect(pricePoint.formattedPrice, equals('€0.01'));
      });

      test('handles large prices', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 999.99,
        );

        expect(pricePoint.effectivePrice, equals(999.99));
        expect(pricePoint.formattedPrice, equals('€999.99'));
      });

      test('handles promotion that reduces price to zero', () {
        final promotion = PricePromotion.fixedDiscount(
          description: '€5 off',
          amount: 5.00,
        );

        final pricePoint = PricePoint(
          date: testDate,
          price: 3.00,
          promotion: promotion,
        );

        expect(pricePoint.effectivePrice, equals(0.0));
        expect(pricePoint.savingsAmount, equals(3.00));
      });

      test('handles empty store name', () {
        final pricePoint = PricePoint(
          date: testDate,
          price: 3.50,
          storeName: '',
        );

        expect(pricePoint.priceDescription, equals('€3.50 at '));
      });
    });
  });
}