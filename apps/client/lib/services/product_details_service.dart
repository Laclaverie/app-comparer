import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:client_price_comparer/database/app_database.dart';

import 'package:shared_models/models/price/price_point.dart';
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_promotion.dart';
import 'package:shared_models/models/promotion/promotion_type.dart';
import 'package:shared_models/models/product/product_statistics.dart';

/// Provides comprehensive product information and analysis services
/// Handles price history, store comparisons, statistics, and user actions like favorites
/// Integrates with database operations and promotion calculations
class ProductDetailsService {
  final AppDatabase _database;
  final String _serverBaseUrl = 'http://192.168.18.5:8080';
  final Logger _logger = Logger('ProductDetailsService');

  ProductDetailsService(this._database);

  /// Get price history for a product
  Future<List<PricePoint>> getPriceHistory(int productId) async {
    // TODO: Implement real database query
    // For now, return mock data with promotions
    return _getMockPriceHistory();
  }

  /// Flux principal : local d'abord, puis serveur
  Future<List<StorePrice>> getStorePrices(int productId) async {
    _logger.info('Getting store prices for product $productId');
    
    // 1. Chercher en local d'abord
    List<StorePrice> localPrices = await _getLocalStorePrices(productId);
    _logger.info('Found ${localPrices.length} local prices');
    
    // 2. Chercher sur le serveur des données plus récentes
    try {
      final serverPrices = await _getServerStorePrices(productId);
      if (serverPrices.isNotEmpty) {
        _logger.info('Found ${serverPrices.length} server prices');
        
        // 3. Comparer et mettre à jour si nécessaire
        final updatedPrices = await _mergeAndUpdatePrices(productId, localPrices, serverPrices);
        return updatedPrices;
      }
    } catch (e) {
      _logger.warning('Server prices failed, using local data: $e');
    }
    
    // 4. Retourner les données locales si le serveur échoue
    return localPrices.isNotEmpty ? localPrices : _getMockStorePrices();
  }

  /// Récupérer les prix depuis la base locale
  Future<List<StorePrice>> _getLocalStorePrices(int productId) async {
    try {
      final query = _database.select(_database.priceHistory).join([
        leftOuterJoin(_database.supermarkets, 
            _database.supermarkets.id.equalsExp(_database.priceHistory.supermarketId))
      ])..where(_database.priceHistory.productId.equals(productId));

      final results = await query.get();
      
      return results.map((row) {
        final priceData = row.readTable(_database.priceHistory);
        final storeData = row.readTableOrNull(_database.supermarkets);
        
        return StorePrice(
          storeName: storeData?.name ?? 'Unknown Store',
          price: priceData.price,
          isCurrentStore: false, // TODO: déterminer le magasin actuel
          lastUpdated: priceData.date,
        );
      }).toList();
    } catch (e) {
      _logger.warning('Local price query failed: $e');
      return [];
    }
  }

  /// Récupérer les prix depuis le serveur (uniquement les plus récents)
  Future<List<StorePrice>> _getServerStorePrices(int productId) async {
    // 1. Récupérer le timestamp de la donnée la plus récente en local
    final lastLocalUpdate = await _getLastLocalUpdateTime(productId);
    
    // 2. Construire l'URL avec le paramètre since
    final uri = Uri.parse('$_serverBaseUrl/api/products/$productId/prices')
        .replace(queryParameters: {
      if (lastLocalUpdate != null) 
        'since': lastLocalUpdate.toIso8601String(),
    });

    _logger.info('Requesting server prices since: ${lastLocalUpdate ?? "beginning"}');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      _logger.info('Server returned ${data.length} newer prices');
      
      return data.map((item) => StorePrice(
        storeName: item['storeName'],
        price: item['price'].toDouble(),
        isCurrentStore: false,
        lastUpdated: DateTime.parse(item['lastUpdated']),
      )).toList();
    }
    
    throw Exception('Server prices not available');
  }

  /// Récupérer la date de la dernière mise à jour locale
  Future<DateTime?> _getLastLocalUpdateTime(int productId) async {
    try {
      final query = _database.select(_database.priceHistory)
        ..where((p) => p.productId.equals(productId))
        ..orderBy([(p) => OrderingTerm.desc(p.date)])
        ..limit(1);

      final result = await query.getSingleOrNull();
      return result?.date;
    } catch (e) {
      _logger.warning('Failed to get last local update time: $e');
      return null;
    }
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

  /// Sauvegarder un prix en local
  Future<void> _saveLocalPrice(int productId, StorePrice storePrice) async {
    try {
      // Récupérer l'ID du magasin ou le créer
      final storeId = await _getOrCreateStoreId(storePrice.storeName);
      
      // Insérer ou mettre à jour le prix
      await _database.into(_database.priceHistory).insertOnConflictUpdate(
        PriceHistoryCompanion(
          productId: Value(productId),
          supermarketId: Value(storeId),
          price: Value(storePrice.price),
          date: Value(storePrice.lastUpdated),
        ),
      );
    } catch (e) {
      _logger.warning('Failed to save local price: $e');
    }
  }

  /// Récupérer ou créer un magasin
  Future<int> _getOrCreateStoreId(String storeName) async {
    // Chercher le magasin existant
    final existing = await (_database.select(_database.supermarkets)
        ..where((t) => t.name.equals(storeName))).getSingleOrNull();
    
    if (existing != null) {
      return existing.id;
    }
    
    // Créer un nouveau magasin
    return await _database.into(_database.supermarkets).insert(
      SupermarketsCompanion(
        name: Value(storeName),
        location: const Value.absent(),
      ),
    );
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

  // Mock data with promotions
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