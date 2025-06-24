
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'price_statistics_service.dart';

class StoreComparisonService {
  /// Groupe les prix par magasin pour comparaison
  static Map<int, StoreChartData> groupPricesByStore(List<PriceHistoryDto> priceHistory) {
    final Map<int, List<PriceHistoryDto>> groupedByStore = {};
    
    // Grouper par supermarketId
    for (final price in priceHistory) {
      if (!groupedByStore.containsKey(price.supermarketId)) {
        groupedByStore[price.supermarketId] = [];
      }
      groupedByStore[price.supermarketId]!.add(price);
    }
    
    // Créer les données de graphique pour chaque magasin
    final Map<int, StoreChartData> storeData = {};
    
    groupedByStore.forEach((storeId, prices) {
      final sortedPrices = List<PriceHistoryDto>.from(prices)
        ..sort((a, b) => a.date.compareTo(b.date));
      
      final stats = PriceStatisticsService.calculateBasicStats(sortedPrices);
      final color = _getStoreColor(storeId);
      
      storeData[storeId] = StoreChartData(
        storeId: storeId,
        storeName: prices.first.storeName ?? 'Magasin #$storeId',
        prices: sortedPrices,
        stats: stats,
        color: color,
        isVisible: true,
      );
    });
    
    return storeData;
  }

  /// Calcule les points de graphique normalisés pour tous les magasins
  static Map<int, List<Offset>> calculateMultiStorePoints(
    Map<int, StoreChartData> storeData,
    BasicPriceStats globalStats,
  ) {
    final Map<int, List<Offset>> allPoints = {};
    
    storeData.forEach((storeId, data) {
      if (!data.isVisible) return;
      
      final points = <Offset>[];
      
      for (int i = 0; i < data.prices.length; i++) {
        final price = data.prices[i].price;
        final x = i / (data.prices.length - 1); // Normalisé 0-1
        final y = 1 - ((price - globalStats.minPrice) / (globalStats.maxPrice - globalStats.minPrice));
        points.add(Offset(x, y));
      }
      
      allPoints[storeId] = points;
    });
    
    return allPoints;
  }

  /// Calcule les statistiques globales pour tous les magasins sélectionnés
  static BasicPriceStats calculateGlobalStats(Map<int, StoreChartData> storeData) {
    final allPrices = <double>[];
    int totalDataPoints = 0;
    
    storeData.values.where((data) => data.isVisible).forEach((data) {
      allPrices.addAll(data.prices.map((p) => p.price));
      totalDataPoints += data.prices.length;
    });
    
    if (allPrices.isEmpty) {
      return BasicPriceStats.empty();
    }
    
    final minPrice = allPrices.reduce((a, b) => a < b ? a : b);
    final maxPrice = allPrices.reduce((a, b) => a > b ? a : b);
    final avgPrice = allPrices.reduce((a, b) => a + b) / allPrices.length;
    
    // Calculer volatilité globale
    final variance = allPrices.map((p) => (p - avgPrice) * (p - avgPrice)).reduce((a, b) => a + b) / allPrices.length;
    final double volatility = variance > 0 ? (avgPrice > 0 ? (math.sqrt(variance) / avgPrice) : 0) : 0;
    
    return BasicPriceStats(
      minPrice: minPrice,
      maxPrice: maxPrice,
      avgPrice: avgPrice,
      volatility: volatility,
      dataPointsCount: totalDataPoints,
    );
  }

  static Color _getStoreColor(int storeId) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return colors[storeId % colors.length];
  }
}

class StoreChartData {
  final int storeId;
  final String storeName;
  final List<PriceHistoryDto> prices;
  final BasicPriceStats stats;
  final Color color;
  final bool isVisible;

  const StoreChartData({
    required this.storeId,
    required this.storeName,
    required this.prices,
    required this.stats,
    required this.color,
    required this.isVisible,
  });

  StoreChartData copyWith({bool? isVisible}) {
    return StoreChartData(
      storeId: storeId,
      storeName: storeName,
      prices: prices,
      stats: stats,
      color: color,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}