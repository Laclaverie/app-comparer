import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_models/models/product/productdto.dart';
import 'app_database.dart';
import 'mappers/product_mapper.dart';

class DatabaseWrapper {
  final AppDatabase _database;

  DatabaseWrapper(this._database);

  // ===========================================
  // MÉTHODES PRIX AVEC MAGASINS
  // ===========================================

  /// Récupérer le prix le plus récent par magasin pour un produit
  Future<List<PriceHistoryWithStore>> getLatestPricesByStore(int productId) async {
    try {
      final allPrices = await (_database.select(_database.priceHistory).join([
        leftOuterJoin(
          _database.supermarkets,
          _database.supermarkets.id.equalsExp(_database.priceHistory.supermarketId),
        ),
      ])..where(_database.priceHistory.productId.equals(productId))
       ..orderBy([OrderingTerm.desc(_database.priceHistory.date)]))
      .get();

      final Map<int, PriceHistoryWithStore> latestByStore = {};
      
      for (final row in allPrices) {
        final priceData = row.readTable(_database.priceHistory);
        final storeData = row.readTableOrNull(_database.supermarkets);
        
        if (!latestByStore.containsKey(priceData.supermarketId)) {
          latestByStore[priceData.supermarketId] = PriceHistoryWithStore(
            priceHistory: priceData,
            supermarket: storeData,
          );
        }
      }
      
      return latestByStore.values.toList();
    } catch (e) {
      throw Exception('Failed to get latest prices by store: $e');
    }
  }

  /// Récupérer l'historique des prix avec filtre par magasin
  Future<List<PriceHistoryWithStore>> getPriceHistoryWithStores(
    int productId, {
    String? storeFilter,
    int? limitDays,
  }) async {
    try {
      var query = _database.select(_database.priceHistory).join([
        leftOuterJoin(
          _database.supermarkets,
          _database.supermarkets.id.equalsExp(_database.priceHistory.supermarketId),
        ),
      ])..where(_database.priceHistory.productId.equals(productId));

      if (storeFilter != null) {
        query = query..where(_database.supermarkets.name.equals(storeFilter));
      }

      if (limitDays != null) {
        final sinceDate = DateTime.now().subtract(Duration(days: limitDays));
        query = query..where(_database.priceHistory.date.isBiggerThanValue(sinceDate));
      }

      query = query..orderBy([OrderingTerm.asc(_database.priceHistory.date)]);

      final results = await query.get();
      
      return results.map((row) {
        final priceData = row.readTable(_database.priceHistory);
        final storeData = row.readTableOrNull(_database.supermarkets);
        
        return PriceHistoryWithStore(
          priceHistory: priceData,
          supermarket: storeData,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get price history with stores: $e');
    }
  }

  // ===========================================
  // MÉTHODES MAGASINS
  // ===========================================

  /// Récupérer ou créer un magasin
  Future<int> getOrCreateStore(String storeName) async {
    try {
      final existing = await (_database.select(_database.supermarkets)
        ..where((t) => t.name.equals(storeName)))
        .getSingleOrNull();
      
      if (existing != null) {
        return existing.id;
      }
      
      // ✅ CORRECTION : Utiliser les champs corrects
      return await _database.insertSupermarket(SupermarketsCompanion.insert(
        name: storeName,
        address: const Value(''), // ✅ address au lieu de location
        city: const Value(''),
        isActive: const Value(true),
      ));
    } catch (e) {
      throw Exception('Failed to get or create store: $e');
    }
  }

  // ===========================================
  // MÉTHODES HISTORIQUE PRIX
  // ===========================================

  /// Récupérer la dernière mise à jour pour un produit
  Future<DateTime?> getLastUpdateTime(int productId) async {
    try {
      final result = await (_database.select(_database.priceHistory)
        ..where((p) => p.productId.equals(productId))
        ..orderBy([(p) => OrderingTerm.desc(p.date)])
        ..limit(1))
        .getSingleOrNull();
      
      return result?.date;
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarder un prix avec gestion des conflits
  Future<void> savePriceHistory({
    required int productId,
    required int supermarketId,
    required double price,
    required DateTime date,
    bool isPromotion = false,
    String? promotionDescription,
    double? originalPrice,
    String source = 'manual',
  }) async {
    try {
      await _database.insertPriceHistory(PriceHistoryCompanion.insert(
        productId: productId,
        supermarketId: supermarketId,
        price: price,
        date: date,
        isPromotion: Value(isPromotion),
        promotionDescription: Value(promotionDescription),
        originalPrice: Value(originalPrice),
        source: Value(source),
        isValidated: const Value(false),
      ));
    } catch (e) {
      throw Exception('Failed to save price history: $e');
    }
  }

  /// Vérifier si on a des données pour un produit
  Future<bool> hasDataForProduct(int productId) async {
    try {
      final results = await (_database.select(_database.priceHistory)
        ..where((p) => p.productId.equals(productId)))
        .get();
      
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ===========================================
  // MÉTHODES PRODUITS - ✅ MISE À JOUR COMPLÈTE
  // ===========================================

  /// Sauvegarder un produit scanné depuis un DTO
  Future<void> saveScannedProductFromDto(ProductDto productDto) async {
    try {
      final existing = await _database.getProductById(productDto.id!);
      
      if (existing != null) {
        // Mettre à jour en préservant les données de cache
        final updateCompanion = productDto.toUpdateCompanion(
          existingId: existing.id,
          lastScannedAt: DateTime.now(), // ✅ Marquer comme scanné maintenant
          scanCount: existing.scanCount + 1, // ✅ Incrémenter le compteur
          isCachedLocally: true,
        );
        await _database.updateProduct(updateCompanion);
      } else {
        // Insérer nouveau produit
        final insertCompanion = productDto.toInsertCompanion().copyWith(
          lastScannedAt: Value(DateTime.now()),
          scanCount: const Value(1),
        );
        await _database.insertProduct(insertCompanion);
      }
      
      debugPrint('Product ${productDto.name} saved to local database');
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  /// Récupérer un produit local et le convertir en DTO
  Future<ProductDto?> getLocalProductAsDto(int productId) async {
    try {
      final result = await _database.getProductById(productId);
      return result?.toDto();
    } catch (e) {
      throw Exception('Failed to get local product: $e');
    }
  }

  /// Récupérer un produit par code-barres
  Future<ProductDto?> getProductByBarcodeAsDto(int barcode) async {
    try {
      final result = await (_database.select(_database.products)
        ..where((tbl) => tbl.barcode.equals(barcode)))
        .getSingleOrNull();
      
      return result?.toDto();
    } catch (e) {
      throw Exception('Failed to get product by barcode: $e');
    }
  }

  /// Récupérer tous les produits scannés récemment
  Future<List<ProductDto>> getRecentlyScannedProducts({int limitDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      
      final results = await (_database.select(_database.products)
        ..where((tbl) => 
            tbl.lastScannedAt.isNotNull() & 
            tbl.lastScannedAt.isBiggerThanValue(cutoffDate))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastScannedAt)]))
        .get();
      
      return results.map((result) => result.toDto()).toList();
    } catch (e) {
      throw Exception('Failed to get recent products: $e');
    }
  }

  /// Mettre à jour le timestamp de scan
  Future<void> updateLastScannedAt(int productId) async {
    try {
      final existing = await _database.getProductById(productId);
      if (existing != null) {
        await (_database.update(_database.products)
          ..where((tbl) => tbl.id.equals(productId)))
          .write(ProductsCompanion(
            lastScannedAt: Value(DateTime.now()),
            scanCount: Value(existing.scanCount + 1),
            updatedAt: Value(DateTime.now()),
          ));
      }
    } catch (e) {
      throw Exception('Failed to update last scanned: $e');
    }
  }

  /// Vérifier si un produit existe en local
  Future<bool> hasLocalProduct(int productId) async {
    try {
      final result = await _database.getProductById(productId);
      return result != null;
    } catch (e) {
      return false;
    }
  }

  // ===========================================
  // MÉTHODES DE NETTOYAGE
  // ===========================================

  /// Nettoyer les anciennes données (plus de X jours)
  Future<void> cleanOldPriceHistory({int keepDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      await (_database.delete(_database.priceHistory)
        ..where((p) => p.date.isSmallerThanValue(cutoffDate)))
        .go();
    } catch (e) {
      // Log l'erreur mais ne pas faire échouer l'app
      debugPrint('Warning: Failed to clean old price history: $e');
    }
  }

  /// Nettoyer les anciens produits pour contrôler la taille
  Future<void> cleanupOldProducts({int keepDays = 180}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      await (_database.delete(_database.products)
        ..where((tbl) => 
            tbl.lastScannedAt.isNotNull() & 
            tbl.lastScannedAt.isSmallerThanValue(cutoffDate)))
        .go();
        
      debugPrint('Cleaned up products older than $keepDays days');
    } catch (e) {
      throw Exception('Failed to cleanup old products: $e');
    }
  }

  /// Supprimer l'historique des prix avant une date donnée
  Future<void> deletePriceHistoryBefore(DateTime cutoffDate) async {
    try {
      await (_database.delete(_database.priceHistory)
        ..where((tbl) => tbl.date.isSmallerThanValue(cutoffDate)))
        .go();
    } catch (e) {
      throw Exception('Failed to delete old price history: $e');
    }
  }

  // ===========================================
  // MÉTHODES STATISTIQUES
  // ===========================================

  /// Compter le nombre total d'entrées dans l'historique
  Future<int> countPriceHistoryEntries() async {
    try {
      final count = await _database.select(_database.priceHistory).get();
      return count.length;
    } catch (e) {
      throw Exception('Failed to count price history entries: $e');
    }
  }

  /// Obtenir la taille approximative de la base de données
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final priceHistoryCount = await _database.select(_database.priceHistory).get();
      final supermarketsCount = await _database.select(_database.supermarkets).get();
      final productsCount = await _database.select(_database.products).get();
      final brandsCount = await _database.select(_database.brands).get();
      final categoriesCount = await _database.select(_database.categories).get();
      
      return {
        'priceHistory': priceHistoryCount.length,
        'supermarkets': supermarketsCount.length,
        'products': productsCount.length,
        'brands': brandsCount.length,
        'categories': categoriesCount.length,
      };
    } catch (e) {
      throw Exception('Failed to get database stats: $e');
    }
  }

  /// Garder seulement les N entrées les plus récentes
  Future<void> keepOnlyRecentEntries(int maxEntries) async {
    try {
      final totalCount = await countPriceHistoryEntries();
      if (totalCount <= maxEntries) return;

      // Récupérer les IDs des entrées à garder
      final entriesToKeep = await (_database.select(_database.priceHistory)
        ..orderBy([
          (tbl) => OrderingTerm.desc(tbl.date),
        ])
        ..limit(maxEntries))
        .get();

      if (entriesToKeep.isNotEmpty) {
        final idsToKeep = entriesToKeep.map((e) => e.id).toList();
        await (_database.delete(_database.priceHistory)
          ..where((tbl) => tbl.id.isNotIn(idsToKeep)))
          .go();
      }
    } catch (e) {
      throw Exception('Failed to keep recent entries: $e');
    }
  }

  /// Nettoyage intelligent : supprimer les doublons
  Future<void> removeDuplicatePrices() async {
    try {
      // Note: Cette query SQL brute pourrait ne pas marcher selon la DB
      // Alternative plus sûre : récupérer en Dart et supprimer
      final allPrices = await _database.select(_database.priceHistory).get();
      final seen = <String, int>{};
      final duplicateIds = <int>[];

      for (final price in allPrices) {
        final key = '${price.productId}_${price.supermarketId}_${price.price.toStringAsFixed(2)}_${price.date.day}';
        if (seen.containsKey(key)) {
          duplicateIds.add(price.id);
        } else {
          seen[key] = price.id;
        }
      }

      if (duplicateIds.isNotEmpty) {
        await (_database.delete(_database.priceHistory)
          ..where((tbl) => tbl.id.isIn(duplicateIds)))
          .go();
        debugPrint('Removed ${duplicateIds.length} duplicate prices');
      }
    } catch (e) {
      throw Exception('Failed to remove duplicate prices: $e');
    }
  }

  // ===========================================
  // MÉTHODES SYNCHRONISATION
  // ===========================================

  /// Récupérer les produits non synchronisés
  Future<List<ProductDto>> getUnsyncedProducts() async {
    try {
      final products = await _database.getUnsyncedProducts();
      return products.map((p) => p.toDtoForSync()).toList();
    } catch (e) {
      throw Exception('Failed to get unsynced products: $e');
    }
  }

  /// Marquer un produit comme synchronisé
  Future<void> markProductAsSynced(int productId) async {
    try {
      await _database.markProductAsSynced(productId);
    } catch (e) {
      throw Exception('Failed to mark product as synced: $e');
    }
  }
}

/// Classe helper pour retourner prix + magasin
class PriceHistoryWithStore {
  final PriceHistoryData priceHistory;
  final Supermarket? supermarket; // ✅ Correct

  PriceHistoryWithStore({
    required this.priceHistory,
    this.supermarket,
  });

  /// Helper pour affichage
  String get storeName => supermarket?.name ?? 'Magasin inconnu';
  String get storeAddress => supermarket?.address ?? '';
  double get price => priceHistory.price;
  DateTime get date => priceHistory.date;
  bool get isPromotion => priceHistory.isPromotion;
  String? get promotionDescription => priceHistory.promotionDescription;
}