import 'dart:async' show  TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException; // ✅ AJOUT
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
  final String _serverBaseUrl = 'http://192.168.18.6:8080';
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
  Future<List<PricePoint>> getPriceHistory(
  int barcode, {
  String? storeFilter,
  int limitDays = 30, // ✅ NOUVEAU : Configurable
}) async {
    return await _cacheManager.getCachedPriceHistory(
      barcode,
      storeFilter,
      () => _fetchPriceHistoryWithFallback(
        barcode, 
        storeFilter: storeFilter,
        limitDays: limitDays, // ✅ Passer le paramètre
      ),
    );
  }

  /// Get store prices avec cache
  Future<List<StorePrice>> getStorePrices(int barcode) async {
    var cachedProduct = await _cacheManager.getCachedStorePrices(
      barcode,
      () => _fetchStorePricesWithFallback(barcode),
    );
    
    // Si pas de données locales, checker le serveur
    if (cachedProduct.isEmpty) {
      try {
        cachedProduct = await _getCurrentServerStorePrices(barcode);
        if (cachedProduct.isEmpty) {
          _logger.warning('No store prices available for barcode $barcode');
          return [];
        }
        // Sauvegarder en cache local
        await _cacheManager.saveStorePrices(barcode, cachedProduct);
        return cachedProduct;
      } catch (e) {
        _logger.warning('Failed to fetch store prices from server: $e');
        return []; // ✅ Retourner liste vide au lieu de mock
      }
    }
    
    // Si la dernière donnée est trop vieille (1 jour), on va chercher sur le serveur
    final lastUpdate = cachedProduct.lastOrNull?.lastUpdated;
    if (lastUpdate != null && DateTime.now().difference(lastUpdate).inDays > 1) {
      try {
        final serverPrices = await _getCurrentServerStorePrices(barcode);
        if (serverPrices.isNotEmpty) {
          cachedProduct = await _mergeAndUpdateStorePrices(
            barcode, 
            cachedProduct, 
            serverPrices,
          );
          return cachedProduct;
        }
      } catch (e) {
        _logger.warning('Failed to fetch store prices from server: $e');
      }
    }
    return cachedProduct; // Retourner les données locales même si le serveur échoue
  }

  /// Fetch avec fallback (local → serveur → vide)
  Future<List<PricePoint>> _fetchPriceHistoryWithFallback(
  int barcode, {
  String? storeFilter,
  int limitDays = 30, // ✅ NOUVEAU paramètre
}) async {
    // 1. Chercher en local d'abord par BARCODE
    List<PricePoint> localHistory = await _getLocalPriceHistory(
      barcode, 
      storeFilter: storeFilter,
      limitDays: limitDays, // ✅ Passer le paramètre
    );
    
    // 2. Si pas assez de données récentes, chercher sur le serveur
    final needsServerData = _needsServerUpdate(localHistory, limitDays); // ✅ Paramètre
    
    if (needsServerData) {
      try {
        final serverHistory = await _getServerPriceHistory(
          barcode, 
          storeFilter: storeFilter,
          limitDays: limitDays, // ✅ Passer le paramètre
        );
        if (serverHistory.isNotEmpty) {
          final updatedHistory = await _mergeAndUpdatePriceHistory(
            barcode, localHistory, serverHistory
          );
          return updatedHistory;
        }
      } catch (e) {
        _logger.warning('Server fetch failed, using local: $e');
      }
    }
    
    // 4. Retourner local ou liste vide
    return localHistory; // ✅ Plus de fallback vers mock
  }

  /// Fetch store prices avec fallback
  Future<List<StorePrice>> _fetchStorePricesWithFallback(int barcode) async {
    List<StorePrice> localPrices = await _getCurrentLocalStorePrices(barcode);
    
    final needsUpdate = _needsStorePricesUpdate(localPrices);
    
    if (needsUpdate) {
      try {
        final serverPrices = await _getCurrentServerStorePrices(barcode);
        if (serverPrices.isNotEmpty) {
          final updatedPrices = await _mergeAndUpdateStorePrices(barcode, localPrices, serverPrices);
          return updatedPrices;
        }
      } catch (e) {
        _logger.warning('Server prices failed: $e');
      }
    }
    
    return localPrices; // ✅ Plus de fallback vers mock
  }

  /// ✅ AMÉLIORATION : Vérifier si on a besoin de données serveur avec paramètres
  bool _needsServerUpdate(List<PricePoint> localHistory, int limitDays) {
    if (localHistory.isEmpty) return true;
    
    final latestLocal = localHistory.last.date;
    final hoursSinceUpdate = DateTime.now().difference(latestLocal).inHours;
    
    // ✅ LOGIQUE ADAPTATIVE selon la durée demandée
    final maxHoursBeforeUpdate = limitDays > 60 ? 6 : 2; // Plus de tolérance pour long historique
    final minPointsRequired = limitDays > 60 ? 50 : 10; // Plus de points pour long historique
    
    return hoursSinceUpdate > maxHoursBeforeUpdate || localHistory.length < minPointsRequired;
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

  /// ✅ CORRIGÉ : Récupérer l'historique depuis la base locale par BARCODE
  Future<List<PricePoint>> _getLocalPriceHistory(
  int barcode, {
  String? storeFilter,
  int limitDays = 30, // ✅ NOUVEAU paramètre
}) async {
    try {
      final product = await (_database.select(_database.products)
        ..where((tbl) => tbl.barcode.equals(barcode)))
        .getSingleOrNull();
      
      if (product == null) {
        _logger.warning('No product found for barcode $barcode');
        return [];
      }
      
      final results = await _dbWrapper.getPriceHistoryWithStores(
        product.id,
        storeFilter: storeFilter,
        limitDays: limitDays, // ✅ Passer le paramètre
      );
      
      return results.map((result) => PricePoint(
        date: result.priceHistory.date,
        price: result.priceHistory.price,
        storeName: result.supermarket?.name,
        promotion: result.priceHistory.isPromotion ? PricePromotion(
          type: PromotionType.percentageDiscount,
          description: result.priceHistory.promotionDescription ?? 'Promotion',
          parameters: {'percentage': 15.0},
        ) : null,
      )).toList();
    } catch (e) {
      _logger.warning('Local price history query failed: $e');
      return [];
    }
  }

  /// ✅ CORRIGÉ : Récupérer seulement les prix les plus récents par magasin par BARCODE
  Future<List<StorePrice>> _getCurrentLocalStorePrices(int barcode) async {
    try {
      final results = await _dbWrapper.getLatestPricesByStore(barcode);
      
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

  /// ✅ CORRIGÉ : Récupérer la date de la dernière mise à jour locale par BARCODE
  Future<DateTime?> _getLastLocalUpdateTime(int barcode) async {
    try {
      // Récupérer le produit par barcode
      final product = await (_database.select(_database.products)
        ..where((tbl) => tbl.barcode.equals(barcode)))
        .getSingleOrNull();
      
      if (product == null) return null;
      
      return await _dbWrapper.getLastUpdateTime(product.id);
    } catch (e) {
      _logger.warning('Failed to get last local update time: $e');
      return null;
    }
  }

  /// ✅ CORRIGÉ : Récupérer l'historique depuis le serveur par BARCODE
  Future<List<PricePoint>> _getServerPriceHistory(
  int barcode, {
  String? storeFilter,
  int limitDays = 30,
}) async {
  // 1. Récupérer le timestamp de la donnée la plus récente en local
  final lastLocalUpdate = await _getLastLocalUpdateTime(barcode);
  
  // 2. Construire l'URL avec les paramètres
  final queryParams = <String, String>{
    if (lastLocalUpdate != null) 'since': lastLocalUpdate.toIso8601String(),
    if (storeFilter != null) 'storeName': storeFilter,
    'days': limitDays.toString(),
  };

  final uri = Uri.parse('$_serverBaseUrl/api/products/barcode/$barcode/price-history')
      .replace(queryParameters: queryParams);

  _logger.info('Requesting server price history for barcode $barcode ($limitDays days) since: ${lastLocalUpdate ?? "beginning"}');

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  ).timeout(Duration(seconds: limitDays > 60 ? 15 : 10));

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as List;
    _logger.info('Server returned ${data.length} price history points for barcode $barcode');
    
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
  
  throw Exception('Server price history not available for barcode $barcode');
}

  /// ✅ AJOUT : Récupérer les prix actuels depuis le serveur par BARCODE
  Future<List<StorePrice>> _getCurrentServerStorePrices(int barcode) async {
    final uri = Uri.parse('$_serverBaseUrl/api/products/barcode/$barcode/current-prices');
    
    _logger.info('Requesting current server prices for barcode $barcode');
    
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _logger.info('Server returned ${data.length} current prices for barcode $barcode');
        
        return data.map((item) => StorePrice(
          storeName: item['storeName'],
          price: item['price'].toDouble(),
          isCurrentStore: item['isCurrentStore'] ?? false,
          lastUpdated: DateTime.parse(item['lastUpdated']),
          promotion: item['promotion'] != null ? PricePromotion(
            type: PromotionType.percentageDiscount,
            description: item['promotion']['description'] ?? 'Promotion',
            parameters: {'percentage': item['promotion']['discount'] ?? 15.0},
          ) : null,
          storeId: item['storeId'],
        )).toList();
      }
      
      throw ServerException('Server current prices not available (${response.statusCode})');
    } on TimeoutException {
      throw NetworkException('Server request timeout');
    } on SocketException {
      throw NetworkException('Network connection failed');
    }
  }

  /// ✅ SUPPRIMÉ : _mergeAndUpdatePrices (version productId)

  /// ✅ CORRIGÉ : Fusionner et mettre à jour l'historique des prix par BARCODE
  Future<List<PricePoint>> _mergeAndUpdatePriceHistory(
    int barcode,
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
      await _savePriceHistoryPoint(barcode, serverPoint);
      _logger.info('Updated local price history: ${serverPoint.storeName} on ${serverPoint.date}');
    }
    
    // Retourner trié par date
    final result = mergedHistory.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// ✅ CORRIGÉ : Sauvegarder un point d'historique en local par BARCODE
  Future<void> _savePriceHistoryPoint(int barcode, PricePoint point) async {
    try {
      // Récupérer le produit par barcode
      final product = await (_database.select(_database.products)
        ..where((tbl) => tbl.barcode.equals(barcode)))
        .getSingleOrNull();
      
      if (product == null) {
        _logger.warning('Cannot save history: no product found for barcode $barcode');
        return;
      }
      
      final storeId = point.storeName != null 
          ? await _dbWrapper.getOrCreateStore(point.storeName!)
          : null;
      
      if (storeId == null) return;
      
      await _dbWrapper.savePriceHistory(
        productId: product.id,
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

  /// ✅ AJOUT : Sauvegarder un prix en local par BARCODE
  Future<void> _saveLocalPrice(int barcode, StorePrice storePrice) async {
    try {
      // Récupérer le produit par barcode
      final product = await (_database.select(_database.products)
        ..where((tbl) => tbl.barcode.equals(barcode)))
        .getSingleOrNull();
      
      if (product == null) {
        _logger.warning('Cannot save price: no product found for barcode $barcode');
        return;
      }
      
      // Utiliser la nouvelle méthode du wrapper
      await _dbWrapper.saveStorePrices(barcode, [storePrice]);
    } catch (e) {
      _logger.warning('Failed to save local price: $e');
    }
  }

  /// ✅ CORRIGÉ : Calculate product statistics par BARCODE
  Future<ProductStatistics> getProductStatistics(int barcode) async {
    final priceHistory = await getPriceHistory(barcode);
    final storePrices = await getStorePrices(barcode);

    // ✅ GESTION : Vérifier qu'on a des données
    if (priceHistory.isEmpty || storePrices.isEmpty) {
      _logger.warning('Insufficient data for statistics calculation for barcode $barcode');
      throw Exception('Insufficient price data for statistics calculation');
    }

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

  /// ✅ CORRIGÉ : Add product to favorites par BARCODE
  Future<bool> addToFavorites(int barcode) async {
    // TODO: Implement database operation
    return true;
  }

  /// ✅ CORRIGÉ : Set price alert for product par BARCODE
  Future<bool> setPriceAlert(int barcode, double targetPrice) async {
    // TODO: Implement database operation
    return true;
  }

  /// ✅ CORRIGÉ : Delete product and associated data par BARCODE
  Future<bool> deleteProduct(int barcode) async {
    // TODO: Implement database operation with image cleanup
    return true;
  }

  /// ✅ AJOUT : Fusionner et mettre à jour les prix des magasins
  Future<List<StorePrice>> _mergeAndUpdateStorePrices(
    int barcode,
    List<StorePrice> localPrices,
    List<StorePrice> serverPrices,
  ) async {
    final Map<String, StorePrice> mergedPrices = {};
    
    // Créer une clé unique : nom du magasin
    String createKey(StorePrice price) => price.storeName;
    
    // Ajouter les prix locaux
    for (final price in localPrices) {
      mergedPrices[createKey(price)] = price;
    }
    
    // Les données du serveur sont plus récentes par construction
    for (final serverPrice in serverPrices) {
      mergedPrices[createKey(serverPrice)] = serverPrice;
      _logger.info('Updated price for ${serverPrice.storeName}: €${serverPrice.effectivePrice.toStringAsFixed(2)}');
    }
    
    final result = mergedPrices.values.toList();
    
    // Sauvegarder toutes les données fusionnées
    try {
      await _dbWrapper.saveStorePrices(barcode, result);
      _logger.info('Saved ${result.length} merged store prices for barcode $barcode');
    } catch (e) {
      _logger.warning('Failed to save merged store prices: $e');
    }
    
    return result;
  }
}

/// ✅ AJOUTER : Classes d'exception manquantes
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  
  @override
  String toString() => 'ServerException: $message';
}

class DataException implements Exception {
  final String message;
  DataException(this.message);
  
  @override
  String toString() => 'DataException: $message';
}

