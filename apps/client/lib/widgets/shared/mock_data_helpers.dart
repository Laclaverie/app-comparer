import 'package:shared_models/models/price/price_historydto.dart';

class MockDataHelpers {
  static List<PriceHistoryDto> generateMockPrices(int productId) {
    return [
      PriceHistoryDto(
        id: 1,
        productId: productId,
        supermarketId: 1,
        price: 2.49,
        originalPrice: 2.99,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        isPromotion: true,
        promotionDescription: 'Promo spéciale',
        storeName: 'Carrefour',
        storeLocation: 'Centre ville',
        isCurrentStore: false,
      ),
      PriceHistoryDto(
        id: 2,
        productId: productId,
        supermarketId: 2,
        price: 2.89,
        originalPrice: null,
        date: DateTime.now().subtract(const Duration(hours: 5)),
        storeName: 'Leclerc',
        storeLocation: 'Zone commerciale',
        isCurrentStore: true,
      ),
      PriceHistoryDto(
        id: 3,
        productId: productId,
        supermarketId: 3,
        price: 2.35,
        originalPrice: 2.75,
        date: DateTime.now().subtract(const Duration(hours: 1)),
        isPromotion: true,
        storeName: 'Auchan',
        storeLocation: 'Périphérie',
        isCurrentStore: false,
      ),
      PriceHistoryDto(
        id: 4,
        productId: productId,
        supermarketId: 4,
        price: 2.69,
        date: DateTime.now().subtract(const Duration(hours: 3)),
        storeName: 'Intermarché',
        storeLocation: 'Centre ville',
        isCurrentStore: false,
      ),
    ];
  }
}