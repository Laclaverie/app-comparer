import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_distribution.dart' show PriceDistribution;
import 'package:shared_models/models/price/price_historydto.dart';
import 'price_statistics_service.dart';

class PriceChartDataService {
  /// Prépare les données pour le graphique
  static PriceChartData prepareChartData(
    List<PriceHistoryDto> priceHistory,
    bool isAdvancedMode,
  ) {
    if (priceHistory.isEmpty) {
      return PriceChartData.empty();
    }

    final sortedHistory = List<PriceHistoryDto>.from(priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date));

    final stats = isAdvancedMode 
        ? PriceStatisticsService.calculateAdvancedStats(sortedHistory)
        : AdvancedPriceStats.fromBasic(PriceStatisticsService.calculateBasicStats(sortedHistory));

    final points = _calculateChartPoints(sortedHistory, stats.basicStats);
    final outlierIndices = isAdvancedMode ? _findOutlierIndices(sortedHistory, stats.distribution) : <int>[];

    return PriceChartData(
      sortedHistory: sortedHistory,
      stats: stats,
      chartPoints: points,
      outlierIndices: outlierIndices,
    );
  }

  static List<Offset> _calculateChartPoints(List<PriceHistoryDto> history, BasicPriceStats stats) {
    final points = <Offset>[];
    
    for (int i = 0; i < history.length; i++) {
      final price = history[i].price;
      final x = i / (history.length - 1); // Normalisé 0-1
      final y = 1 - ((price - stats.minPrice) / (stats.maxPrice - stats.minPrice)); // Inversé pour affichage
      points.add(Offset(x, y));
    }
    
    return points;
  }

  static List<int> _findOutlierIndices(List<PriceHistoryDto> history, PriceDistribution? distribution) {
    if (distribution == null || !distribution.hasOutliers) return [];
    
    final outlierIndices = <int>[];
    for (int i = 0; i < history.length; i++) {
      if (distribution.outliers.contains(history[i].price)) {
        outlierIndices.add(i);
      }
    }
    return outlierIndices;
  }
}

class PriceChartData {
  final List<PriceHistoryDto> sortedHistory;
  final AdvancedPriceStats stats;
  final List<Offset> chartPoints;
  final List<int> outlierIndices;

  const PriceChartData({
    required this.sortedHistory,
    required this.stats,
    required this.chartPoints,
    required this.outlierIndices,
  });

  factory PriceChartData.empty() => PriceChartData(
    sortedHistory: [],
    stats: AdvancedPriceStats.fromBasic(BasicPriceStats.empty()),
    chartPoints: [],
    outlierIndices: [],
  );

  bool get isEmpty => sortedHistory.isEmpty;
}