// lib/services/price_statistics_service.dart
import 'dart:math' as math;
import 'package:shared_models/models/price/price_historydto.dart';
import 'package:shared_models/models/price/price_trend.dart';
import 'package:shared_models/models/price/price_distribution.dart';

import 'package:client_price_comparer/services/charts/trend_analysis_service.dart';
import 'package:client_price_comparer/services/charts/distribution_analysis_service.dart';
import 'package:client_price_comparer/services/charts/moving_average_service.dart';

class PriceStatisticsService {
  /// Calcule les statistiques basiques d'une liste de prix
  static BasicPriceStats calculateBasicStats(List<PriceHistoryDto> priceHistory) {
    if (priceHistory.isEmpty) {
      return BasicPriceStats.empty();
    }

    final prices = priceHistory.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    // Calculer volatilité
    final variance = prices.map((p) => (p - avgPrice) * (p - avgPrice)).reduce((a, b) => a + b) / prices.length;
    final volatility = math.sqrt(variance) / avgPrice;

    return BasicPriceStats(
      minPrice: minPrice,
      maxPrice: maxPrice,
      avgPrice: avgPrice,
      volatility: volatility,
      dataPointsCount: priceHistory.length,
    );
  }

  /// Calcule les statistiques avancées
  static AdvancedPriceStats calculateAdvancedStats(List<PriceHistoryDto> priceHistory) {
    final basicStats = calculateBasicStats(priceHistory);
    
    if (priceHistory.length < 2) {
      return AdvancedPriceStats.fromBasic(basicStats);
    }

    final trend = TrendAnalysisService.calculateTrend(priceHistory);
    final distribution = DistributionAnalysisService.calculateDistribution(priceHistory);
    final movingAverage = MovingAverageService.calculate(priceHistory, window: 7);

    return AdvancedPriceStats(
      basicStats: basicStats,
      trend: trend,
      distribution: distribution,
      movingAverage: movingAverage,
    );
  }
}

/// Statistiques de base
class BasicPriceStats {
  final double minPrice;
  final double maxPrice;
  final double avgPrice;
  final double volatility;
  final int dataPointsCount;

  const BasicPriceStats({
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
    required this.volatility,
    required this.dataPointsCount,
  });

  factory BasicPriceStats.empty() => const BasicPriceStats(
    minPrice: 0,
    maxPrice: 0,
    avgPrice: 0,
    volatility: 0,
    dataPointsCount: 0,
  );

  bool get isEmpty => dataPointsCount == 0;
}

/// Statistiques avancées
class AdvancedPriceStats {
  final BasicPriceStats basicStats;
  final PriceTrend? trend;
  final PriceDistribution? distribution;
  final List<double> movingAverage;

  const AdvancedPriceStats({
    required this.basicStats,
    this.trend,
    this.distribution,
    required this.movingAverage,
  });

  factory AdvancedPriceStats.fromBasic(BasicPriceStats basic) => AdvancedPriceStats(
    basicStats: basic,
    movingAverage: [],
  );
}