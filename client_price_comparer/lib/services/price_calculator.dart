import '../models/store/store_price.dart';
import 'promotion_calculator.dart';

/// Provides price calculation utilities for store prices with promotion support
/// Handles effective price calculations, savings analysis, and price comparisons
/// Integrates with promotion calculator to determine real costs for consumers
class PriceCalculator {
  /// Get the effective price for a store, considering promotions
  static double getEffectivePrice(StorePrice storePrice) {
    if (storePrice.promotion == null) {
      return storePrice.price;
    }
    
    if (!PromotionCalculator.isPromotionValid(storePrice.promotion!)) {
      return storePrice.price;
    }
    
    return PromotionCalculator.calculateEffectivePrice(
      storePrice.promotion!, 
      storePrice.price
    );
  }
  
  /// Calculate savings amount from promotion
  static double getSavingsAmount(StorePrice storePrice) {
    return storePrice.price - getEffectivePrice(storePrice);
  }
  
  /// Calculate savings percentage from promotion
  static double getSavingsPercentage(StorePrice storePrice) {
    final savings = getSavingsAmount(storePrice);
    return (savings / storePrice.price) * 100;
  }
  
  /// Check if a store price has an active promotion
  static bool hasActivePromotion(StorePrice storePrice) {
    return storePrice.promotion != null && 
           PromotionCalculator.isPromotionValid(storePrice.promotion!);
  }
  
  /// Compare two store prices and return the better deal
  static StorePrice getBetterDeal(StorePrice price1, StorePrice price2) {
    final effective1 = getEffectivePrice(price1);
    final effective2 = getEffectivePrice(price2);
    return effective1 <= effective2 ? price1 : price2;
  }
  
  /// Find the best deal from a list of store prices
  static StorePrice findBestDeal(List<StorePrice> storePrices) {
    if (storePrices.isEmpty) {
      throw ArgumentError('Cannot find best deal from empty list');
    }
    
    return storePrices.reduce((best, current) => getBetterDeal(best, current));
  }
  
  /// Calculate price difference between two stores
  static double calculatePriceDifference(StorePrice store1, StorePrice store2) {
    return getEffectivePrice(store2) - getEffectivePrice(store1);
  }
  
  /// Calculate percentage difference between two stores
  static double calculatePercentageDifference(StorePrice store1, StorePrice store2) {
    final price1 = getEffectivePrice(store1);
    final price2 = getEffectivePrice(store2);
    return ((price2 - price1) / price1) * 100;
  }
}