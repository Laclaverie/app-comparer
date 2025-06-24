import 'dart:math' as math;
import 'package:shared_models/models/price/price_historydto.dart';
import 'package:shared_models/models/price/price_trend.dart';

class TrendAnalysisService {
  /// Calcule la tendance des prix
  static PriceTrend? calculateTrend(List<PriceHistoryDto> priceHistory) {
    if (priceHistory.length < 2) return null;

    final sortedHistory = List<PriceHistoryDto>.from(priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    final startPrice = sortedHistory.first.price;
    final endPrice = sortedHistory.last.price;
    final changeAmount = endPrice - startPrice;
    final changePercentage = (changeAmount / startPrice) * 100;

    final direction = _determineTrendDirection(changePercentage);
    final prices = sortedHistory.map((p) => p.price).toList();
    final trendStrength = _calculateTrendStrength(prices);

    return PriceTrend(
      direction: direction,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
      startDate: sortedHistory.first.date,
      endDate: sortedHistory.last.date,
      historicalPrices: prices,
      trendStrength: trendStrength,
    );
  }

  static TrendDirection _determineTrendDirection(double changePercentage) {
    if (changePercentage.abs() < 2) {
      return TrendDirection.stable;
    } else if (changePercentage > 0) {
      return TrendDirection.increasing;
    } else {
      return TrendDirection.decreasing;
    }
  }

  static double _calculateTrendStrength(List<double> prices) {
    if (prices.length < 2) return 0;
    
    // Corrélation linéaire simple
    final n = prices.length;
    final indices = List.generate(n, (i) => i.toDouble());
    
    final meanX = indices.reduce((a, b) => a + b) / n;
    final meanY = prices.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double denomX = 0;
    double denomY = 0;
    
    for (int i = 0; i < n; i++) {
      final diffX = indices[i] - meanX;
      final diffY = prices[i] - meanY;
      numerator += diffX * diffY;
      denomX += diffX * diffX;
      denomY += diffY * diffY;
    }
    
    if (denomX == 0 || denomY == 0) return 0;
    
    final correlation = numerator / math.sqrt(denomX * denomY);
    return correlation.abs();
  }
}