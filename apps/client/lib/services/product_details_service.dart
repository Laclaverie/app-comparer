import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/database/database_wrapper.dart';

import 'package:shared_models/models/price/price_point.dart';
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_promotion.dart';
import 'package:shared_models/models/promotion/promotion_type.dart';
import 'package:shared_models/models/product/product_statistics.dart';

import 'cache_manager.dart';

/// Provides comprehensive product information and analysis services
/// Handles price history, store comparisons, statistics, and user actions like favorites
/// Integrates with database operations and promotion calculations
class ProductDetailsService {
  final AppDatabase _database;
  late final DatabaseWrapper _dbWrapper;
  late final CacheManager _cacheManager;
  final String _serverBaseUrl = 'http://192.168.18.5:8080';
  final Logger _logger = Logger('ProductDetailsService');

  ProductDetailsService(this._database) {
    _dbWrapper = DatabaseWrapper(_database);
    _cacheManager = CacheManager(_dbWrapper);
    
    // Nettoyer la DB au démarrage (async, non-bloquant)
    _initCleanup();
  }

  void _initCleanup() {
    Future.microtask(() async {
      try {
        await _cacheManager.cleanupDatabase();
      } catch (e) {
        _logger.warning('Initial cleanup failed: $e');
      }
    });
  }

  /// Get price history avec cache intelligent
  Future<List<PricePoint>> getPriceHistory(int productId, {String? storeFilter}) async {
    return await _cacheManager.getCachedPriceHistory(
      productId,
      storeFilter,
      () => _fetchPriceHistoryWithFallback(productId, storeFilter: storeFilter),
    );
  }

  /// Get store prices avec cache
  Future<List<StorePrice>> getStorePrices(int productId) async {
    return await _cacheManager.getCachedStorePrices(
      productId,
      () => _fetchStorePricesWithFallback(productId),
    );
  }

  /// Fetch avec fallback (local → serveur → mock)
  Future<List<PricePoint>> _fetchPriceHistoryWithFallback(int productId, {String? storeFilter}) async {
    // 1. Chercher en local d'abord
    List<PricePoint> localHistory = await _getLocalPriceHistory(productId, storeFilter: storeFilter);
    
    // 2. Si pas assez de données récentes, chercher sur le serveur
    final needsServerData = _needsServerUpdate(localHistory);
    
    if (needsServerData) {
      try {
        final serverHistory = await _getServerPriceHistory(productId, storeFilter: storeFilter);
        if (serverHistory.isNotEmpty) {
          // 3. Fusionner et sauvegarder
          final updatedHistory = await _mergeAndUpdatePriceHistory(productId, localHistory, serverHistory);
          return updatedHistory;
        }
      } catch (e) {
        _logger.warning('Server fetch failed, using local: $e');
      }
    }
    
    // 4. Retourner local ou mock
    return localHistory.isNotEmpty ? localHistory : _getMockPriceHistory();
  }

  /// Fetch store prices avec fallback
  Future<List<StorePrice>> _fetchStorePricesWithFallback(int productId) async {
    List<StorePrice> localPrices = await _getCurrentLocalStorePrices(productId);
    
    final needsUpdate = _needsStorePricesUpdate(localPrices);
    
    if (needsUpdate) {
      try {
        final serverPrices = await _getCurrentServerStorePrices(productId);
        if (serverPrices.isNotEmpty) {
          final updatedPrices = await _mergeAndUpdatePrices(productId, localPrices, serverPrices);
          return updatedPrices;
        }
      } catch (e) {
        _logger.warning('Server prices failed: $e');
      }
    }
    
    return localPrices.isNotEmpty ? localPrices : _getMockStorePrices();
  }

  /// Vérifier si on a besoin de données serveur
  bool _needsServerUpdate(List<PricePoint> localHistory) {
    if (localHistory.isEmpty) return true;
    
    final latestLocal = localHistory.last.date;
    final hoursSinceUpdate = DateTime.now().difference(latestLocal).inHours;
    
    // Mettre à jour si > 2 heures ou < 10 points
    return hoursSinceUpdate > 2 || localHistory.length < 10;
  }

  /// Vérifier si les prix magasins ont besoin d'update
  bool _needsStorePricesUpdate(List<StorePrice> localPrices) {
    if (localPrices.isEmpty) return true;
    
    final oldestUpdate = localPrices
        .map((p) => p.lastUpdated)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    final minutesSinceUpdate = DateTime.now().difference(oldestUpdate).inMinutes;
    
    // Mettre à jour si > 15 minutes
    return minutesSinceUpdate > 15;
  }

  /// Nettoyer le cache (à appeler périodiquement)
  Future<void> clearCache() async {
    _cacheManager.clearMemoryCache();
  }

  /// Récupérer l'historique depuis la base locale - AVEC WRAPPER
  Future<List<PricePoint>> _getLocalPriceHistory(int productId, {String? storeFilter}) async {
    try {
      final results = await _dbWrapper.getPriceHistoryWithStores(
        productId,
        storeFilter: storeFilter,
        limitDays: 30,
      );
      
      return results.map((result) {
        return PricePoint(
          date: result.priceHistory.date,
          price: result.priceHistory.price,
          storeName: result.supermarket?.name,
          promotion: result.priceHistory.isPromotion ? PricePromotion(
            type: PromotionType.percentageDiscount,
            description: result.priceHistory.promotionDescription ?? 'Promotion',
            parameters: {'percentage': 15.0},
          ) : null,
        );
      }).toList();
    } catch (e) {
      _logger.warning('Local price history query failed: $e');
      return [];
    }
  }

  /// Récupérer seulement les prix les plus récents par magasin - AVEC WRAPPER
  Future<List<StorePrice>> _getCurrentLocalStorePrices(int productId) async {
    try {
      final results = await _dbWrapper.getLatestPricesByStore(productId);
      
      return results.map((result) {
        return StorePrice(
          storeName: result.supermarket?.name ?? 'Unknown Store',
          price: result.priceHistory.price,
          isCurrentStore: false, // TODO: déterminer le magasin actuel
          lastUpdated: result.priceHistory.date,
        );
      }).toList();
    } catch (e) {
      _logger.warning('Current local prices query failed: $e');
      return [];
    }
  }

  /// Récupérer la date de la dernière mise à jour locale - AVEC WRAPPER
  Future<DateTime?> _getLastLocalUpdateTime(int productId) async {
    try {
      return await _dbWrapper.getLastUpdateTime(productId);
    } catch (e) {
      _logger.warning('Failed to get last local update time: $e');
      return null;
    }
  }

  /// Récupérer ou créer un magasin - AVEC WRAPPER
  Future<int> _getOrCreateStoreId(String storeName) async {
    return await _dbWrapper.getOrCreateStore(storeName);
  }

  /// Sauvegarder un prix en local - AVEC WRAPPER
  Future<void> _saveLocalPrice(int productId, StorePrice storePrice) async {
    try {
      final storeId = await _getOrCreateStoreId(storePrice.storeName);
      
      await _dbWrapper.savePriceHistory(
        productId: productId,
        supermarketId: storeId,
        price: storePrice.price,
        date: storePrice.lastUpdated,
      );
    } catch (e) {
      _logger.warning('Failed to save local price: $e');
    }
  }

  /// Sauvegarder un point d'historique en local - AVEC WRAPPER
  Future<void> _savePriceHistoryPoint(int productId, PricePoint point) async {
    try {
      final storeId = point.storeName != null 
          ? await _getOrCreateStoreId(point.storeName!)
          : null;
      
      if (storeId == null) return;
      
      await _dbWrapper.savePriceHistory(
        productId: productId,
        supermarketId: storeId,
        price: point.price,
        date: point.date,
        isPromotion: point.promotion != null,
        promotionDescription: point.promotion?.description,
      );
    } catch (e) {
      _logger.warning('Failed to save price history point: $e');
    }
  }

  /// Récupérer l'historique depuis le serveur
  Future<List<PricePoint>> _getServerPriceHistory(int productId, {String? storeFilter}) async {
    // 1. Récupérer le timestamp de la donnée la plus récente en local
    final lastLocalUpdate = await _getLastLocalUpdateTime(productId);
    
    // 2. Construire l'URL avec les paramètres
    final queryParams = <String, String>{
      if (lastLocalUpdate != null) 'since': lastLocalUpdate.toIso8601String(),
      if (storeFilter != null) 'storeName': storeFilter,
      'days': '30', // Limiter à 30 jours
    };

    final uri = Uri.parse('$_serverBaseUrl/api/products/$productId/price-history')
        .replace(queryParameters: queryParams);

    _logger.info('Requesting server price history since: ${lastLocalUpdate ?? "beginning"}');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      _logger.info('Server returned ${data.length} price history points');
      
      return data.map((item) => PricePoint(
        date: DateTime.parse(item['date']),
        price: item['price'].toDouble(),
        storeName: item['storeName'],
        promotion: item['isPromotion'] == true ? PricePromotion(
          type: PromotionType.percentageDiscount,
          description: item['promotionDescription'] ?? 'Promotion',
          parameters: {'percentage': 15.0},
        ) : null,
      )).toList();
    }
    
    throw Exception('Server price history not available');
  }

  /// Récupérer les prix actuels depuis le serveur
  Future<List<StorePrice>> _getCurrentServerStorePrices(int productId) async {
    // Récupérer seulement les prix les plus récents
    final uri = Uri.parse('$_serverBaseUrl/api/products/$productId/prices')
        .replace(queryParameters: {
      'current': 'true', // ← Paramètre pour l'endpoint
    });

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => StorePrice(
        storeName: item['storeName'],
        price: item['price'].toDouble(),
        isCurrentStore: false,
        lastUpdated: DateTime.parse(item['lastUpdated']),
      )).toList();
    }
    
    throw Exception('Server current prices not available');
  }

  /// Fusionner et mettre à jour les prix (version optimisée)
  Future<List<StorePrice>> _mergeAndUpdatePrices(
    int productId, 
    List<StorePrice> localPrices, 
    List<StorePrice> serverPrices
  ) async {
    final Map<String, StorePrice> mergedPrices = {};
    
    // Ajouter les prix locaux
    for (final price in localPrices) {
      mergedPrices[price.storeName] = price;
    }
    
    // Les prix du serveur sont déjà plus récents par construction
    // donc on peut les ajouter/remplacer directement
    for (final serverPrice in serverPrices) {
      mergedPrices[serverPrice.storeName] = serverPrice;
      
      // Sauvegarder en local
      await _saveLocalPrice(productId, serverPrice);
      _logger.info('Updated local price for ${serverPrice.storeName}: €${serverPrice.price}');
    }
    
    return mergedPrices.values.toList();
  }

  /// Fusionner et mettre à jour l'historique des prix
  Future<List<PricePoint>> _mergeAndUpdatePriceHistory(
    int productId, 
    List<PricePoint> localHistory, 
    List<PricePoint> serverHistory
  ) async {
    final Map<String, PricePoint> mergedHistory = {};
    
    // Créer une clé unique : date + magasin
    String createKey(PricePoint point) {
      final dateKey = point.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      return '${dateKey}_${point.storeName ?? 'unknown'}';
    }
    
    // Ajouter l'historique local
    for (final point in localHistory) {
      mergedHistory[createKey(point)] = point;
    }
    
    // Les données du serveur sont plus récentes par construction
    for (final serverPoint in serverHistory) {
      mergedHistory[createKey(serverPoint)] = serverPoint;
      
      // Sauvegarder en local si nouveau
      await _savePriceHistoryPoint(productId, serverPoint);
      _logger.info('Updated local price history: ${serverPoint.storeName} on ${serverPoint.date}');
    }
    
    // Retourner trié par date
    final result = mergedHistory.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Calculate product statistics considering effective prices
  Future<ProductStatistics> getProductStatistics(int productId) async {
    final priceHistory = await getPriceHistory(productId);
    final storePrices = await getStorePrices(productId);

    // Use effective prices for calculations
    final effectivePrices = priceHistory.map((p) => p.effectivePrice).toList();
    effectivePrices.sort();

    final averagePrice = effectivePrices.reduce((a, b) => a + b) / effectivePrices.length;
    final medianPrice = effectivePrices.length % 2 == 0
        ? (effectivePrices[effectivePrices.length ~/ 2 - 1] + effectivePrices[effectivePrices.length ~/ 2]) / 2
        : effectivePrices[effectivePrices.length ~/ 2];
    
    final minPrice = effectivePrices.first;
    final maxPrice = effectivePrices.last;
    
    final variance = effectivePrices.map((p) => (p - averagePrice) * (p - averagePrice))
        .reduce((a, b) => a + b) / effectivePrices.length;

    // Calculate standard deviation
    final standardDeviation = sqrt(variance);

    // Sort stores by effective price for best/worst deals
    final sortedStores = List<StorePrice>.from(storePrices)
      ..sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));

    return ProductStatistics(
      averagePrice: averagePrice,
      medianPrice: medianPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceVariance: variance,
      standardDeviation: standardDeviation,
      bestDeal: sortedStores.first,
      worstDeal: sortedStores.last,
      allPrices: storePrices,
      calculatedAt: DateTime.now(),
    );
  }

  /// Add product to favorites
  Future<bool> addToFavorites(int productId) async {
    // TODO: Implement database operation
    return true;
  }

  /// Set price alert for product
  Future<bool> setPriceAlert(int productId, double targetPrice) async {
    // TODO: Implement database operation
    return true;
  }

  /// Delete product and associated data
  Future<bool> deleteProduct(int productId) async {
    // TODO: Implement database operation with image cleanup
    return true;
  }

  // Mock data with promotions (inchangé)
  List<PricePoint> _getMockPriceHistory() {
    return [
      PricePoint(date: DateTime.now().subtract(const Duration(days: 30)), price: 4.00),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 25)), price: 3.85),
      PricePoint(
        date: DateTime.now().subtract(const Duration(days: 20)), 
        price: 3.75,
        promotion: PricePromotion(
          type: PromotionType.percentageDiscount,
          description: '20% off',
          parameters: {'percentage': 20.0},
        ),
      ),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 15)), price: 3.60),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 10)), price: 3.50),
      PricePoint(date: DateTime.now().subtract(const Duration(days: 5)), price: 3.45),
      PricePoint(date: DateTime.now(), price: 3.29),
    ];
  }

  List<StorePrice> _getMockStorePrices() {
    return [
      // Regular price - becomes worst deal
      StorePrice(
        storeName: "Monoprix",
        price: 3.29,
        isCurrentStore: true,
        lastUpdated: DateTime.now(),
      ),
      
      // Buy 3 Get 4 deal - effective 25% discount per unit
      StorePrice(
        storeName: "IGA",
        price: 3.60, // Higher base price but good deal with promotion
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        promotion: PricePromotion(
          type: PromotionType.buyXGetY,
          description: 'Buy 3 Get 4',
          parameters: {'buyQuantity': 3, 'getQuantity': 1}, // Total 4 units for price of 3
          validTo: DateTime.now().add(const Duration(days: 7)),
        ),
      ),
      
      // 2 for €6 deal
      StorePrice(
        storeName: "Super U",
        price: 3.50, // Regular price
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
        promotion: PricePromotion(
          type: PromotionType.buyXForY,
          description: '2 for €6',
          parameters: {'quantity': 2, 'totalPrice': 6.0}, // €3 per unit when buying 2
          validTo: DateTime.now().add(const Duration(days: 3)),
        ),
      ),
      
      // Simple percentage discount
      StorePrice(
        storeName: "Produit laitier",
        price: 3.80,
        isCurrentStore: false,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
        promotion: PricePromotion(
          type: PromotionType.percentageDiscount,
          description: '15% off',
          parameters: {'percentage': 15.0},
          validTo: DateTime.now().add(const Duration(days: 2)),
        ),
      ),
    ];
  }
}