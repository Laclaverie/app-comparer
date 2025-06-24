import 'package:shared_models/models/price/price_historydto.dart';
import '../data_database.dart';

extension PriceHistoryDataToDto on PriceHistoryData {
  PriceHistoryDto toDto({
    String? storeName,
    String? storeLocation,
    bool isCurrentStore = false,
  }) {
    return PriceHistoryDto(
      id: id,
      productId: productId,
      supermarketId: supermarketId,
      price: price,
      originalPrice: originalPrice,
      date: date,
      isPromotion: isPromotion,
      promotionDescription: promotionDescription,
      storeName: storeName,
      storeLocation: storeLocation,
      isCurrentStore: isCurrentStore,
      promotion: isPromotion ? PromotionDto(
        description: promotionDescription ?? 'Promotion',
        discount: _calculateDiscount(originalPrice, price),
      ) : null,
    );
  }

  double? _calculateDiscount(double? originalPrice, double currentPrice) {
    if (originalPrice == null || originalPrice <= currentPrice) return null;
    return ((originalPrice - currentPrice) / originalPrice * 100);
  }
}