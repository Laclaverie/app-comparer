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

  ///  Calcule la sélection intelligente par défaut
  static Set<int> calculateSmartDefaultSelection(
    Map<int, StoreChartData> storeData, {
    bool isAdvancedMode = false,
  }) {
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) {
      // Si aucun prix, sélectionner le premier magasin disponible
      return storeData.keys.take(1).toSet();
    }

    // ✅ Trouver le magasin avec le meilleur prix récent
    final bestPriceStore = _findBestPriceStore(storesWithPrices);
    final selectedStores = <int>{bestPriceStore};

    // ✅ En mode avancé, ajouter des magasins pour comparaison
    if (isAdvancedMode) {
      selectedStores.addAll(_findComparisonStores(storesWithPrices, bestPriceStore));
    }

    return selectedStores;
  }

  /// ✅ Trouve le magasin avec le meilleur prix récent
  static int _findBestPriceStore(List<MapEntry<int, StoreChartData>> storesWithPrices) {
    final today = DateTime.now();
    final storeScores = <int, double>{};

    for (final entry in storesWithPrices) {
      final storeId = entry.key;
      final storeData = entry.value;
      
      // Trier les prix par date (plus récent en premier)
      final sortedPrices = storeData.prices.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      
      final latestPrice = sortedPrices.first;
      final priceDate = latestPrice.date;

      // Calculer un score basé sur le prix et la fraîcheur des données
      final daysSincePrice = today.difference(priceDate).inDays;
      final freshnessMultiplier = 1 + (daysSincePrice * 0.001); // Légère pénalité par jour
      final adjustedPrice = latestPrice.price * freshnessMultiplier;
      
      storeScores[storeId] = adjustedPrice;
    }

    // Retourner le magasin avec le meilleur score (prix le plus bas ajusté)
    return storeScores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// ✅ Trouve des magasins supplémentaires pour comparaison en mode avancé
  static Set<int> _findComparisonStores(
    List<MapEntry<int, StoreChartData>> storesWithPrices, 
    int bestPriceStore
  ) {
    final comparisonStores = <int>{};
    
    // 1. Ajouter le magasin avec le plus de données (historique)
    final mostDataStore = storesWithPrices
        .where((entry) => entry.key != bestPriceStore)
        .fold<MapEntry<int, StoreChartData>?>(null, (prev, current) {
          if (prev == null) return current;
          return current.value.prices.length > prev.value.prices.length ? current : prev;
        });
    
    if (mostDataStore != null) {
      comparisonStores.add(mostDataStore.key);
    }

    // 2. Ajouter 1-2 magasins avec les prix les plus compétitifs
    final sortedByPrice = storesWithPrices
        .where((entry) => entry.key != bestPriceStore && !comparisonStores.contains(entry.key))
        .map((entry) {
          final latestPrice = entry.value.prices
              .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
          return MapEntry(entry.key, latestPrice.price);
        })
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Ajouter jusqu'à 2 magasins supplémentaires
    for (int i = 0; i < 2 && i < sortedByPrice.length; i++) {
      comparisonStores.add(sortedByPrice[i].key);
    }

    return comparisonStores;
  }

  /// ✅ NOUVEAU : Identifie le magasin champion (meilleur prix)
  static int? findBestPriceStoreId(Map<int, StoreChartData> storeData) {
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) return null;

    return _findBestPriceStore(storesWithPrices);
  }

  /// ✅ NOUVEAU : Obtient le prix le plus récent d'un magasin
  static double? getLatestPrice(StoreChartData storeData) {
    if (storeData.prices.isEmpty) return null;
    
    final sortedPrices = storeData.prices.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedPrices.first.price;
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