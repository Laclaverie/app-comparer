import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// ✅ Import des tables locales (plus shared_models)
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Products, Brands, Categories, Supermarkets, PriceHistory, Users],
)
class AppDatabase extends _$AppDatabase {
  // ✅ Constructeur par défaut : nouvelle base propre
  AppDatabase() : super(driftDatabase(name: 'app_database_v5_clean'));
  
  // ✅ Constructeur interne avec QueryExecutor
  AppDatabase._internal(super.executor);
  
  // ✅ Factory pour créer une instance de l'ancienne base (SANS underscore)
  static AppDatabase createOldDb() {
    return AppDatabase._internal(driftDatabase(name: 'app_database'));
  }
  
  // ✅ Factory pour créer une instance de la nouvelle base (SANS underscore)
  static AppDatabase createNewDb() {
    return AppDatabase._internal(driftDatabase(name: 'app_database_v5_clean'));
  }

  // ✅ NOUVEAU : Factory pour les tests (base en mémoire)
  static AppDatabase forTesting() {
    return AppDatabase._internal(NativeDatabase.memory(),
    );
  }

  @override
  int get schemaVersion => 1; // ✅ Version 1 pour la nouvelle base propre

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      debugPrint('✅ [DB] Nouvelle base V5 créée - Prête pour l\'import');
    },
  );

  // ✅ Retirer les méthodes de migration V2→V3, V3→V4, etc.
  // Garder seulement les méthodes CRUD

  // ===========================================
  // MÉTHODES PRODUITS (Version nettoyée)
  // ===========================================
  
  Future<List<Product>> getAllProducts() async {
    // ✅ Version simple car nouvelle base propre
    return await select(products).get();
  }

  Future<int> insertProduct(ProductsCompanion product) async {
    return await into(products).insert(product);
  }

  Future<List<Product>> searchProductsByName(String query) async {
    return await (select(products)
          ..where((p) => p.name.like('%$query%')))
        .get();
  }

  Future<Product?> getProductById(int productId) async {
    return await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcodeString) async {
    // Convertir String → int pour la recherche
    final barcode = int.tryParse(barcodeString);
    if (barcode == null) return null;
    
    return await (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<bool> updateProduct(ProductsCompanion product) async {
    final rowsAffected = await update(products).replace(product);
    return rowsAffected;
  }

  Future<bool> deleteProduct(int productId) async {
    final rowsAffected = await (delete(products)..where((p) => p.id.equals(productId))).go();
    return rowsAffected > 0;
  }

  // ===========================================
  // MÉTHODES MARQUES
  // ===========================================
  
  Future<int> insertBrand(BrandsCompanion brand) async {
    return await into(brands).insert(brand);
  }

  Future<Brand?> getBrandById(int brandId) async {
    return await (select(brands)..where((b) => b.id.equals(brandId))).getSingleOrNull();
  }

  Future<List<Brand>> getAllBrands() async {
    return await select(brands).get();
  }

  Future<bool> updateBrand(BrandsCompanion brand) async {
    final rowsAffected = await update(brands).replace(brand);
    return rowsAffected;
  }

  Future<bool> deleteBrand(int brandId) async {
    final rowsAffected = await (delete(brands)..where((b) => b.id.equals(brandId))).go();
    return rowsAffected > 0;
  }

  // ===========================================
  // MÉTHODES CATÉGORIES
  // ===========================================
  
  Future<int> insertCategory(CategoriesCompanion category) async {
    return await into(categories).insert(category);
  }

  Future<Category?> getCategoryById(int categoryId) async {
    return await (select(categories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();
  }

  Future<List<Category>> getAllCategories() async {
    return await select(categories).get();
  }

  Future<bool> updateCategory(CategoriesCompanion category) async {
    final rowsAffected = await update(categories).replace(category);
    return rowsAffected;
  }

  Future<bool> deleteCategory(int categoryId) async {
    final rowsAffected = await (delete(categories)..where((c) => c.id.equals(categoryId))).go();
    return rowsAffected > 0;
  }

  // ===========================================
  // MÉTHODES SUPERMARCHÉS
  // ===========================================
  
  Future<int> insertSupermarket(SupermarketsCompanion supermarket) async {
    return await into(supermarkets).insert(supermarket);
  }

  Future<Supermarket?> getSupermarketById(int supermarketId) async {
    return await (select(supermarkets)..where((s) => s.id.equals(supermarketId))).getSingleOrNull();
  }

  Future<List<Supermarket>> getAllSupermarkets() async {
    return await select(supermarkets).get();
  }

  Future<bool> updateSupermarket(SupermarketsCompanion supermarket) async {
    final rowsAffected = await update(supermarkets).replace(supermarket);
    return rowsAffected;
  }

  Future<bool> deleteSupermarket(int supermarketId) async {
    final rowsAffected = await (delete(supermarkets)..where((s) => s.id.equals(supermarketId))).go();
    return rowsAffected > 0;
  }

  // ===========================================
  // MÉTHODES HISTORIQUE PRIX
  // ===========================================
  
  Future<int> insertPriceHistory(PriceHistoryCompanion priceHistory) async {
    return await into(this.priceHistory).insert(priceHistory);
  }

  Future<List<PriceHistoryData>> getPriceHistoryForProduct(int productId) async {
    return await (select(priceHistory)..where((p) => p.productId.equals(productId))).get();
  }

  Future<List<PriceHistoryData>> getAllPriceHistory() async {
    return await select(priceHistory).get();
  }

  Future<bool> updatePriceHistory(PriceHistoryCompanion priceHistory) async {
    final rowsAffected = await update(this.priceHistory).replace(priceHistory);
    return rowsAffected;
  }

  Future<bool> deletePriceHistory(int priceHistoryId) async {
    final rowsAffected = await (delete(priceHistory)..where((p) => p.id.equals(priceHistoryId))).go();
    return rowsAffected > 0;
  }

  // ===========================================
  // MÉTHODES UTILITAIRES PRODUITS
  // ===========================================

  // ✅ AJOUT : Méthode manquante pour marquer comme scanné
  Future<bool> markProductAsScanned(int productId) async {
    try {
      final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          scanCount: Value(1), // Incrémenter de 1 (ou récupérer la valeur actuelle et +1)
          lastScannedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('❌ Error marking product as scanned: $e');
      return false;
    }
  }

  // ✅ AJOUT : Méthode pour incrémenter correctement le scan_count
  Future<bool> incrementScanCount(int productId) async {
    try {
      // Récupérer le produit actuel
      final product = await getProductById(productId);
      if (product == null) return false;
      
      // Incrémenter le compteur
      final newCount = (product.scanCount) + 1;
      
      final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          scanCount: Value(newCount),
          lastScannedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      
      debugPrint('✅ Product $productId scan count updated to $newCount');
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('❌ Error incrementing scan count: $e');
      return false;
    }
  }

  // ===========================================
  // MÉTHODES DE RECHERCHE AVANCÉE
  // ===========================================

  Future<List<Product>> searchProductsByBrand(int brandId) async {
    return await (select(products)..where((p) => p.brandId.equals(brandId))).get();
  }

  Future<List<Product>> searchProductsByCategory(int categoryId) async {
    return await (select(products)..where((p) => p.categoryId.equals(categoryId))).get();
  }

  Future<List<Product>> getActiveProducts() async {
    return await (select(products)..where((p) => p.isActive.equals(true))).get();
  }

  Future<List<Product>> getRecentlyScannedProducts({int limit = 10}) async {
    return await (select(products)
      ..where((p) => p.lastScannedAt.isNotNull())
      ..orderBy([(p) => OrderingTerm.desc(p.lastScannedAt)])
      ..limit(limit)
    ).get();
  }

  // ===========================================
  // MÉTHODES DE STATISTIQUES
  // ===========================================

  Future<int> getTotalProductsCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM products').getSingle();
    return result.data['count'] as int;
  }

  Future<int> getActiveBrandsCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM brands WHERE is_active = 1').getSingle();
    return result.data['count'] as int;
  }

  Future<int> getActiveCategoriesCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM categories WHERE is_active = 1').getSingle();
    return result.data['count'] as int;
  }

  Future<int> getTotalPriceEntriesCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM price_history').getSingle();
    return result.data['count'] as int;
  }

  // ===========================================
  // MÉTHODES DE SYNCHRONISATION
  // ===========================================

  /// Récupérer les produits non synchronisés
  Future<List<Product>> getUnsyncedProducts() async {
    try {
      return await (select(products)
        ..where((p) => p.lastSyncedAt.isNull() | 
                      (p.lastSyncedAt.isNotNull() & p.updatedAt.isNotNull() & 
                       p.updatedAt.isBiggerThan(p.lastSyncedAt))))
        .get();
    } catch (e) {
      debugPrint('❌ Error getting unsynced products: $e');
      return [];
    }
  }

  /// ✅ AJOUT : Méthode manquante - Marquer un produit comme synchronisé
  Future<bool> markProductAsSynced(int productId) async {
    try {
      final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          lastSyncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      
      debugPrint('✅ Product $productId marked as synced');
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('❌ Error marking product as synced: $e');
      return false;
    }
  }

  /// Marquer plusieurs produits comme synchronisés
  Future<int> markMultipleProductsAsSynced(List<int> productIds) async {
    try {
      int totalUpdated = 0;
      final syncTime = DateTime.now();
      
      for (final productId in productIds) {
        final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(
            lastSyncedAt: Value(syncTime),
            updatedAt: Value(syncTime),
          ));
        
        if (rowsAffected > 0) totalUpdated++;
      }
      
      debugPrint('✅ $totalUpdated products marked as synced');
      return totalUpdated;
    } catch (e) {
      debugPrint('❌ Error marking multiple products as synced: $e');
      return 0;
    }
  }

  /// Obtenir les produits modifiés depuis la dernière synchronisation
  Future<List<Product>> getModifiedProductsSinceLastSync() async {
    try {
      return await (select(products)
        ..where((p) => p.lastSyncedAt.isNotNull() & 
                      p.updatedAt.isNotNull() &
                      p.updatedAt.isBiggerThan(p.lastSyncedAt)))
        .get();
    } catch (e) {
      debugPrint('❌ Error getting modified products: $e');
      return [];
    }
  }

  /// Obtenir les produits jamais synchronisés
  Future<List<Product>> getNeverSyncedProducts() async {
    try {
      return await (select(products)
        ..where((p) => p.lastSyncedAt.isNull()))
        .get();
    } catch (e) {
      debugPrint('❌ Error getting never synced products: $e');
      return [];
    }
  }

  /// Réinitialiser le statut de synchronisation (pour forcer une re-sync)
  Future<bool> resetSyncStatus(int productId) async {
    try {
      final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          lastSyncedAt: const Value.absent(), // Remettre à null
          updatedAt: Value(DateTime.now()),
        ));
      
      debugPrint('✅ Product $productId sync status reset');
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('❌ Error resetting sync status: $e');
      return false;
    }
  }

  /// Obtenir le timestamp de la dernière synchronisation globale
  Future<DateTime?> getLastGlobalSyncTime() async {
    try {
      final result = await (select(products)
        ..where((p) => p.lastSyncedAt.isNotNull())
        ..orderBy([(p) => OrderingTerm.desc(p.lastSyncedAt)])
        ..limit(1))
        .getSingleOrNull();
      
      return result?.lastSyncedAt;
    } catch (e) {
      debugPrint('❌ Error getting last global sync time: $e');
      return null;
    }
  }

  /// Compter les produits en attente de synchronisation
  Future<int> countUnsyncedProducts() async {
    try {
      final products = await getUnsyncedProducts();
      return products.length;
    } catch (e) {
      debugPrint('❌ Error counting unsynced products: $e');
      return 0;
    }
  }

  // ===========================================
  // MÉTHODES UTILITAIRES SUPPLÉMENTAIRES
  // ===========================================

  /// ✅ BONUS : Méthode pour marquer comme mis en cache localement
  Future<bool> markProductAsCachedLocally(int productId, bool isCached) async {
    try {
      final rowsAffected = await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
          isCachedLocally: Value(isCached),
          updatedAt: Value(DateTime.now()),
        ));
      
      debugPrint('✅ Product $productId cache status: $isCached');
      return rowsAffected > 0;
    } catch (e) {
      debugPrint('❌ Error updating cache status: $e');
      return false;
    }
  }

  /// Obtenir les statistiques de synchronisation
  Future<Map<String, int>> getSyncStatistics() async {
    try {
      final totalProducts = await select(products).get();
      final unsyncedProducts = await getUnsyncedProducts();
      final neverSyncedProducts = await getNeverSyncedProducts();
      final modifiedProducts = await getModifiedProductsSinceLastSync();
      
      return {
        'total': totalProducts.length,
        'unsynced': unsyncedProducts.length,
        'never_synced': neverSyncedProducts.length,
        'modified': modifiedProducts.length,
        'synced': totalProducts.length - unsyncedProducts.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting sync statistics: $e');
      return {
        'total': 0,
        'unsynced': 0,
        'never_synced': 0,
        'modified': 0,
        'synced': 0,
      };
    }
  }
}
