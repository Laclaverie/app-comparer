// apps/client/lib/database/database_wrapper.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class DatabaseWrapper {
  final AppDatabase _database;

  DatabaseWrapper(this._database);

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

  /// Récupérer ou créer un magasin
  Future<int> getOrCreateStore(String storeName) async {
    try {
      final existing = await (_database.select(_database.supermarkets)
        ..where((t) => t.name.equals(storeName)))
        .getSingleOrNull();
      
      if (existing != null) {
        return existing.id;
      }
      
      return await _database.into(_database.supermarkets).insert(
        SupermarketsCompanion(
          name: Value(storeName),
          location: const Value.absent(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to get or create store: $e');
    }
  }

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
  }) async {
    try {
      await _database.into(_database.priceHistory).insertOnConflictUpdate(
        PriceHistoryCompanion(
          productId: Value(productId),
          supermarketId: Value(supermarketId),
          price: Value(price),
          date: Value(date),
          isPromotion: Value(isPromotion),
          promotionDescription: promotionDescription != null 
              ? Value(promotionDescription)
              : const Value.absent(),
        ),
      );
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

  /// Nettoyer les anciennes données (plus de X jours)
  Future<void> cleanOldPriceHistory({int keepDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      await (_database.delete(_database.priceHistory)
        ..where((p) => p.date.isSmallerThanValue(cutoffDate)))
        .go();
    } catch (e) {
      // Log l'erreur mais ne pas faire échouer l'app
    }
  }
}

/// Classe helper pour retourner prix + magasin
class PriceHistoryWithStore {
  final PriceHistoryData priceHistory;
  final Supermarket? supermarket; // ✅ Correction : Supermarket au lieu de SupermarketsData

  PriceHistoryWithStore({
    required this.priceHistory,
    this.supermarket,
  });
}