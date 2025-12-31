import 'dart:math';
import 'package:shared_models/models/price/price_historydto.dart';

// Extension pour faciliter les null checks
extension LetExtension<T> on T? {
  R? let<R>(R Function(T) block) => this != null ? block(this as T) : null;
}

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

  /// Génère un historique de prix mock
  static List<PriceHistoryDto> generateMockPriceHistory(int productId, int periodDays) {
    final List<PriceHistoryDto> history = [];
    final now = DateTime.now();
    final random = Random();

    // Prix de base
    double basePrice = 2.50;
    const List<String> stores = ['Carrefour', 'Leclerc', 'Auchan', 'Intermarché', 'Monoprix'];

    // Générer des points de données sur la période
    for (int i = 0; i < periodDays; i += 2) {
      final date = now.subtract(Duration(days: i));

      // Variation du prix (+/- 10%)
      final variation = (random.nextDouble() - 0.5) * 0.2; // -10% à +10%
      final price = basePrice * (1 + variation);

      // Promotion occasionnelle
      final isPromotion = random.nextDouble() < 0.3; // 30% de chance
      final originalPrice = isPromotion ? price * 1.2 : null;

      for (int storeIdx = 0; storeIdx < stores.length; storeIdx++) {
        // Pas tous les magasins à chaque date
        if (random.nextDouble() < 0.7) {
          history.add(PriceHistoryDto(
            id: history.length + 1,
            productId: productId,
            supermarketId: storeIdx + 1,
            price: double.parse(price.toStringAsFixed(2)),
            originalPrice: originalPrice?.let((p) => double.parse(p.toStringAsFixed(2))),
            date: date,
            isPromotion: isPromotion,
            promotionDescription: isPromotion ? 'Promo ${(random.nextDouble() * 30 + 10).round()}%' : null,
            storeName: stores[storeIdx],
            storeLocation: 'Centre ville',
            isCurrentStore: storeIdx == 0,
          ));
        }
      }

      // Ajuster le prix de base pour la prochaine itération (tendance)
      basePrice += (random.nextDouble() - 0.5) * 0.05; // Légère dérive
      basePrice = basePrice.clamp(1.5, 4.0); // Bornes réalistes
    }

    return history..sort((a, b) => b.date.compareTo(a.date));
  }
}