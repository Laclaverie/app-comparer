import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/models/price_models.dart';

import 'package:client_price_comparer/models/store_price.dart';
import 'package:client_price_comparer/models/price_promotion.dart';
import 'package:client_price_comparer/models/promotion_type.dart';

/// Provides comprehensive product information and analysis services
/// Handles price history, store comparisons, statistics, and user actions like favorites
/// Integrates with database operations and promotion calculations
class ProductDetailsService {
  final AppDatabase _database;

  ProductDetailsService(this._database);

  /// Get price history for a product
  Future<List<PricePoint>> getPriceHistory(int productId) async {
    // TODO: Implement real database query
    // For now, return mock data with promotions
    return _getMockPriceHistory();
  }

  /// Get store prices for a product
  Future<List<StorePrice>> getStorePrices(int productId) async {
    // TODO: Implement real database query
    // For now, return mock data with promotions
    return _getMockStorePrices();
  }

  /// Calculate product statistics considering effective prices
  Future<ProductStatistics> getProductStatistics(int productId) async {
    final priceHistory = await getPriceHistory(productId);
    final storePrices = await getStorePrices(productId);

    // Use effective prices for calculations
    final effectivePrices = priceHistory.map((p) => p.effectivePrice).toList();
    effectivePrices.sort();

    final averagePrice = effectivePrices.reduce((a, b) => a + b) / effectivePrices.length;
    final medianPrice = effectivePrices.length % 2 == 0
        ? (effectivePrices[effectivePrices.length ~/ 2 - 1] + effectivePrices[effectivePrices.length ~/ 2]) / 2
        : effectivePrices[effectivePrices.length ~/ 2];
    
    final minPrice = effectivePrices.first;
    final maxPrice = effectivePrices.last;
    
    final variance = effectivePrices.map((p) => (p - averagePrice) * (p - averagePrice))
        .reduce((a, b) => a + b) / effectivePrices.length;

    // Sort stores by effective price for best/worst deals
    final sortedStores = List<StorePrice>.from(storePrices)
      ..sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));

    return ProductStatistics(
      averagePrice: averagePrice,
      medianPrice: medianPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceVariance: variance,
      bestDeal: sortedStores.first,
      worstDeal: sortedStores.last,
    );
  }

  /// Add product to favorites
  Future<bool> addToFavorites(int productId) async {
    // TODO: Implement database operation
    return true;
  }

  /// Set price alert for product
  Future<bool> setPriceAlert(int productId, double targetPrice) async {
    // TODO: Implement database operation
    return true;
  }

  /// Delete product and associated data
  Future<bool> deleteProduct(int productId) async {
    // TODO: Implement database operation with image cleanup
    return true;
  }

  // Mock data with promotions
  List<PricePoint> _getMockPriceHistory() {
    return [
      PricePoint(date: DateTime.now().subtract(const Duration(days: 30)), price: 4.00),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 25)), price: 3.85),
      PricePoint(
        date: DateTime.now().subtract(const Duration(days: 20)), 
        price: 3.75,
        promotion: PricePromotion(
          type: PromotionType.percentageDiscount,
          description: '20% off',
          parameters: {'percentage': 20.0},
        ),
      ),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 15)), price: 3.60),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 10)), price: 3.50),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 5)), price: 3.45),
      PricePoint(date: DateTime.now(), price: 3.29),
    ];
  }

  List<StorePrice> _getMockStorePrices() {
    return [
      // Regular price - becomes worst deal
      StorePrice(
        storeName: "Monoprix",
        price: 3.29,
        isCurrentStore: true,
        lastUpdated: DateTime.now(),
      ),
      
      // Buy 3 Get 4 deal - effective 25% discount per unit
      StorePrice(
        storeName: "IGA",
        price: 3.60, // Higher base price but good deal with promotion
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        promotion: PricePromotion(
          type: PromotionType.buyXGetY,
          description: 'Buy 3 Get 4',
          parameters: {'buyQuantity': 3, 'getQuantity': 1}, // Total 4 units for price of 3
          validTo: DateTime.now().add(const Duration(days: 7)),
        ),
      ),
      
      // 2 for €6 deal
      StorePrice(
        storeName: "Super U",
        price: 3.50, // Regular price
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
        promotion: PricePromotion(
          type: PromotionType.buyXForY,
          description: '2 for €6',
          parameters: {'quantity': 2, 'totalPrice': 6.0}, // €3 per unit when buying 2
          validTo: DateTime.now().add(const Duration(days: 3)),
        ),
      ),
      
      // Simple percentage discount
      StorePrice(
        storeName: "Produit laitier",
        price: 3.80,
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
        promotion: PricePromotion(
          type: PromotionType.percentageDiscount,
          description: '15% off',
          parameters: {'percentage': 15.0},
          validTo: DateTime.now().add(const Duration(days: 2)),
        ),
      ),
    ];
  }
}