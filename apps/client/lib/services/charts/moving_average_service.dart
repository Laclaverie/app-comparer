import 'package:shared_models/models/price/price_historydto.dart';

class MovingAverageService {
  /// Calcule la moyenne mobile
  static List<double> calculate(List<PriceHistoryDto> priceHistory, {int window = 7}) {
    final prices = priceHistory.map((p) => p.price).toList();
    return calculateFromPrices(prices, window: window);
  }

  static List<double> calculateFromPrices(List<double> prices, {int window = 7}) {
    if (prices.length < window) return [];
    
    final movingAvg = <double>[];
    for (int i = window - 1; i < prices.length; i++) {
      final sum = prices.sublist(i - window + 1, i + 1).reduce((a, b) => a + b);
      movingAvg.add(sum / window);
    }
    return movingAvg;
  }

  /// Calcule plusieurs moyennes mobiles (court, moyen, long terme)
  static MultipleMovingAverages calculateMultiple(List<PriceHistoryDto> priceHistory) {
    return MultipleMovingAverages(
      short: calculate(priceHistory, window: 3),   // 3 jours
      medium: calculate(priceHistory, window: 7),  // 7 jours
      long: calculate(priceHistory, window: 14),   // 14 jours
    );
  }
}

class MultipleMovingAverages {
  final List<double> short;
  final List<double> medium;
  final List<double> long;

  const MultipleMovingAverages({
    required this.short,
    required this.medium,
    required this.long,
  });
}