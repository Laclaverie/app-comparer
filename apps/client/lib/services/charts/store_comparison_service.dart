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

  /// ✅ Point d'entrée principal pour initialiser la sélection
  static StoreSelectionResult initializeStoreSelection(
    Map<int, StoreChartData> storeData, {
    bool isAdvancedMode = false,
    bool forceReset = false,
  }) {
    // Vérifier si reset forcé ou première initialisation
    final hasExistingSelection = !forceReset && 
        storeData.values.any((store) => store.isVisible) &&
        !_isDefaultSelection(storeData);

    if (hasExistingSelection) {
      // Garder la sélection existante
      return StoreSelectionResult(
        visibility: Map.fromEntries(
          storeData.entries.map((e) => MapEntry(e.key, e.value.isVisible))
        ),
        bestPriceStoreIds: _findBestPriceStoreIds(storeData),
        selectionType: SelectionType.existing,
      );
    } else {
      // Appliquer la sélection intelligente
      final smartSelection = _calculateSmartSelection(storeData, isAdvancedMode);
      return StoreSelectionResult(
        visibility: Map.fromEntries(
          storeData.entries.map((e) => MapEntry(e.key, smartSelection.contains(e.key)))
        ),
        bestPriceStoreIds: _findBestPriceStoreIds(storeData),
        selectionType: SelectionType.smart,
        smartSelectedIds: smartSelection,
      );
    }
  }

  /// ✅ DERNIÈRE VERSION : Calcule la sélection intelligente
  static Set<int> calculateSmartDefaultSelection(
    Map<int, StoreChartData> storeData, {
    bool isAdvancedMode = false,
  }) {
    print('🔍 calculateSmartDefaultSelection appelé');
    print('   - storeData: ${storeData.keys.toList()}');
    print('   - isAdvancedMode: $isAdvancedMode');
    
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) {
      print('   ⚠️  Aucun magasin avec prix, sélection du premier');
      return storeData.keys.take(1).toSet();
    }

    // ✅ Trouver TOUS les magasins avec le meilleur prix
    final bestPriceStores = _findBestPriceStoreIds(storeData);
    print('   🏆 Champion(s): $bestPriceStores');
    
    final selectedStores = Set<int>.from(bestPriceStores);

    // ✅ En mode normal : si plusieurs champions, prendre celui avec le plus de données
    if (!isAdvancedMode && bestPriceStores.length > 1) {
      final bestDataStore = bestPriceStores
          .map((storeId) => MapEntry(storeId, storeData[storeId]!.prices.length))
          .reduce((a, b) => a.value > b.value ? a : b);
      
      print('   📊 Champion avec le plus de données: ${bestDataStore.key} (${bestDataStore.value} prix)');
      return {bestDataStore.key};
    }

    // ✅ En mode avancé : garder tous les champions + ajouter des comparateurs
    if (isAdvancedMode) {
      final comparisonStores = _findComparisonStores(storesWithPrices, bestPriceStores);
      print('   📊 Magasins de comparaison: $comparisonStores');
      selectedStores.addAll(comparisonStores);
    }

    print('   ✅ Sélection finale: $selectedStores');
    return selectedStores;
  }

  /// ✅ DERNIÈRE VERSION : Identifie TOUS les champions (égalités)
  static Set<int> findBestPriceStoreIds(Map<int, StoreChartData> storeData) {
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) return <int>{};

    return _findBestPriceStoreIds(storeData);
  }

  /// ✅ Compatibilité : Garde l'ancienne méthode qui retourne un seul ID
  static int? findBestPriceStoreId(Map<int, StoreChartData> storeData) {
    final bestStores = findBestPriceStoreIds(storeData);
    return bestStores.isNotEmpty ? bestStores.first : null;
  }

  /// ✅ Méthode publique pour obtenir le prix le plus récent
  static double? getLatestPrice(StoreChartData storeData) => _getLatestPrice(storeData);

  // ========================================
  // MÉTHODES PRIVÉES (DERNIÈRES VERSIONS)
  // ========================================

  /// ✅ Détecte si c'est une sélection par défaut
  static bool _isDefaultSelection(Map<int, StoreChartData> storeData) {
    final visibleCount = storeData.values.where((s) => s.isVisible).length;
    return visibleCount == 0 || visibleCount == storeData.length;
  }

  /// ✅ Calcule la sélection intelligente (version interne)
  static Set<int> _calculateSmartSelection(
    Map<int, StoreChartData> storeData, 
    bool isAdvancedMode
  ) {
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) {
      return storeData.keys.take(1).toSet();
    }

    final bestPriceStores = _findBestPriceStoreIds(storeData);
    
    if (!isAdvancedMode) {
      // Mode normal : un seul champion (le plus documenté si égalité)
      if (bestPriceStores.length > 1) {
        final bestDataStore = bestPriceStores
            .map((id) => MapEntry(id, storeData[id]!.prices.length))
            .reduce((a, b) => a.value > b.value ? a : b);
        return {bestDataStore.key};
      }
      return bestPriceStores;
    } else {
      // Mode avancé : champions + comparateurs
      final selection = Set<int>.from(bestPriceStores);
      if (selection.length < 3) {
        selection.addAll(_findComparisonStores(storesWithPrices, bestPriceStores));
      }
      return selection;
    }
  }

  /// ✅ DERNIÈRE VERSION : Trouve les magasins champions (égalités)
  static Set<int> _findBestPriceStoreIds(Map<int, StoreChartData> storeData) {
    final storesWithPrices = storeData.entries
        .where((entry) => entry.value.prices.isNotEmpty)
        .toList();

    if (storesWithPrices.isEmpty) return <int>{};

    final today = DateTime.now();
    final storeScores = <int, double>{};

    for (final entry in storesWithPrices) {
      final latestPrice = _getLatestPrice(entry.value);
      if (latestPrice == null) continue;

      final priceDate = _getLatestPriceDate(entry.value);
      final daysSincePrice = priceDate != null 
          ? today.difference(priceDate).inDays 
          : 999;
      
      final freshnessMultiplier = 1 + (daysSincePrice * 0.001);
      storeScores[entry.key] = latestPrice * freshnessMultiplier;
    }

    if (storeScores.isEmpty) return <int>{};

    final bestPrice = storeScores.values.reduce((a, b) => a < b ? a : b);
    const tolerance = 0.01;
    
    return storeScores.entries
        .where((entry) => (entry.value - bestPrice).abs() <= tolerance)
        .map((entry) => entry.key)
        .toSet();
  }

  /// ✅ Trouve des magasins de comparaison
  static Set<int> _findComparisonStores(
    List<MapEntry<int, StoreChartData>> storesWithPrices, 
    Set<int> bestPriceStores
  ) {
    final comparisonStores = <int>{};
    
    // Magasin avec le plus de données
    final mostDataStore = storesWithPrices
        .where((entry) => !bestPriceStores.contains(entry.key))
        .fold<MapEntry<int, StoreChartData>?>(null, (prev, current) {
          if (prev == null) return current;
          return current.value.prices.length > prev.value.prices.length ? current : prev;
        });
    
    if (mostDataStore != null) {
      comparisonStores.add(mostDataStore.key);
    }

    return comparisonStores;
  }

  /// ✅ Prix le plus récent
  static double? _getLatestPrice(StoreChartData storeData) {
    if (storeData.prices.isEmpty) return null;
    
    final sortedPrices = storeData.prices.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedPrices.first.price;
  }

  /// ✅ Date du prix le plus récent
  static DateTime? _getLatestPriceDate(StoreChartData storeData) {
    if (storeData.prices.isEmpty) return null;
    
    final sortedPrices = storeData.prices.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return sortedPrices.first.date;
  }

  /// ✅ Couleur du magasin
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

// ========================================
// CLASSES DE DONNÉES
// ========================================

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

/// ✅ Résultat de l'initialisation
class StoreSelectionResult {
  final Map<int, bool> visibility;
  final Set<int> bestPriceStoreIds;
  final SelectionType selectionType;
  final Set<int>? smartSelectedIds;

  StoreSelectionResult({
    required this.visibility,
    required this.bestPriceStoreIds,
    required this.selectionType,
    this.smartSelectedIds,
  });
}

enum SelectionType { existing, smart }