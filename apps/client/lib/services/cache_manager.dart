// apps/client/lib/services/cache_manager.dart
import 'dart:collection';
import 'package:client_price_comparer/database/database_wrapper.dart';
import 'package:shared_models/models/price/price_point.dart';
import 'package:shared_models/models/store/store_price.dart';

class CacheManager {
  final DatabaseWrapper _dbWrapper;
  
  // Cache en mémoire pour les données chaudes
  final Map<String, List<PricePoint>> _priceHistoryCache = {};
  final Map<int, List<StorePrice>> _storePricesCache = {};
  final Queue<String> _cacheKeys = Queue(); // Pour LRU
  
  // Limites de cache
  static const int maxCacheEntries = 50; // 50 produits max en mémoire
  static const int maxDbDays = 90; // 90 jours max en DB
  static const int maxDbEntries = 10000; // 10k entrées max en DB
  
  CacheManager(this._dbWrapper);

  int get priceHistoryCacheSize => _priceHistoryCache.length;
  int get storePricesCacheSize => _storePricesCache.length;
  int get totalCacheKeys => _cacheKeys.length;

  /// Nettoyer automatiquement la DB pour contrôler la taille
  Future<void> cleanupDatabase() async {
    try {
      // 1. Supprimer les données anciennes (> 90 jours)
      final cutoffDate = DateTime.now().subtract(const Duration(days: maxDbDays));
      await _dbWrapper.deletePriceHistoryBefore(cutoffDate);
      
      // 2. Si encore trop d'entrées, garder seulement les plus récentes
      final totalEntries = await _dbWrapper.countPriceHistoryEntries();
      if (totalEntries > maxDbEntries) {
        await _dbWrapper.keepOnlyRecentEntries(maxDbEntries);
      }
      
      print('Database cleanup completed. Entries: $totalEntries');
    } catch (e) {
      print('Database cleanup failed: $e');
    }
  }

  /// Cache LRU pour les données en mémoire
  void _manageCacheSize() {
    while (_cacheKeys.length > maxCacheEntries) {
      final oldestKey = _cacheKeys.removeFirst();
      _priceHistoryCache.remove(oldestKey);
    }
  }

  /// Clé de cache pour l'historique des prix
  String _historyKey(int productId, String? storeFilter) {
    return 'history_${productId}_${storeFilter ?? 'all'}';
  }

  /// Cache intelligent pour l'historique des prix
  Future<List<PricePoint>> getCachedPriceHistory(
    int productId, 
    String? storeFilter,
    Future<List<PricePoint>> Function() fetchFunction,
  ) async {
    final key = _historyKey(productId, storeFilter);
    
    // 1. Vérifier le cache mémoire d'abord
    if (_priceHistoryCache.containsKey(key)) {
      _cacheKeys.remove(key); // Refresh LRU
      _cacheKeys.addLast(key);
      return _priceHistoryCache[key]!;
    }
    
    // 2. Fetch les données
    final data = await fetchFunction();
    
    // 3. Sauver en cache mémoire
    _priceHistoryCache[key] = data;
    _cacheKeys.addLast(key);
    _manageCacheSize();
    
    return data;
  }

  /// Cache pour les prix actuels des magasins
  Future<List<StorePrice>> getCachedStorePrices(
    int productId,
    Future<List<StorePrice>> Function() fetchFunction,
  ) async {
    // Cache plus court pour les prix actuels (5 minutes)
    if (_storePricesCache.containsKey(productId)) {
      return _storePricesCache[productId]!;
    }
    
    final data = await fetchFunction();
    _storePricesCache[productId] = data;
    
    // Auto-expiry après 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      _storePricesCache.remove(productId);
    });
    
    return data;
  }

  /// Nettoyer le cache mémoire
  void clearMemoryCache() {
    _priceHistoryCache.clear();
    _storePricesCache.clear();
    _cacheKeys.clear();
  }

  /// ✅ AJOUTER : Obtenir les statistiques du cache
  Map<String, int> getCacheStats() {
    return {
      'priceHistory': _priceHistoryCache.length,
      'storePrices': _storePricesCache.length,
      'totalKeys': _cacheKeys.length,
      'maxEntries': maxCacheEntries,
    };
  }

  /// ✅ AJOUTER : Vérifier si une clé est en cache
  bool hasCachedPriceHistory(int productId, String? storeFilter) {
    final key = _historyKey(productId, storeFilter);
    return _priceHistoryCache.containsKey(key);
  }

  /// ✅ AJOUTER : Vérifier si les prix magasin sont en cache
  bool hasCachedStorePrices(int productId) {
    return _storePricesCache.containsKey(productId);
  }
}