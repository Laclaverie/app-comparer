import 'package:drift/drift.dart';
import '../data_database.dart';

class ProductRepository {
  final DataDatabase database;
  
  ProductRepository(this.database);

  // ✅ DÉLÉGATION : Méthodes simples
  Future<Product?> getProductByBarcode(int barcode) => 
      database.getProductByBarcode(barcode);
  
  Future<List<Product>> getAllProducts() => 
      database.getAllProducts();
  
  Future<int> insertProduct(ProductsCompanion product) => 
      database.insertProduct(product);
  
  Future<bool> updateProduct(ProductsCompanion product) => 
      database.updateProduct(product);
  
  Future<int> deleteProduct(int id) => 
      database.deleteProduct(id);

  // ✅ LOGIQUE COMPLEXE : Recherche par marque(s)
  Future<List<Product>> getProductsByBrandName(String brandName, {int? limit}) async {
    // Validation métier
    if (brandName.trim().isEmpty) {
      throw ArgumentError('Brand name cannot be empty');
    }
    
    final sanitized = brandName.trim();
    if (sanitized.length > 50) {
      throw ArgumentError('Brand name too long (max 50 characters)');
    }

    // ✅ Requête optimisée avec JOIN
    var query = database.select(database.products).join([
      innerJoin(
        database.brands,
        database.brands.id.equalsExp(database.products.brandId),
      ),
    ]);
    
    // Filtre par nom de marque (insensible à la casse)
    query = query..where(database.brands.name.like('%$sanitized%'));
    
    // Limitation optionnelle
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }
    
    // Tri par nom de produit
    query = query..orderBy([OrderingTerm.asc(database.products.name)]);
    
    final results = await query.get();
    
    // Extraire les produits du JOIN
    return results.map((result) => result.readTable(database.products)).toList();
  }

  Future<List<Product>> getProductsByBrandNames(List<String> brandNames, {int? limit}) async {
    // Validation métier
    if (brandNames.isEmpty) {
      throw ArgumentError('Brand names list cannot be empty');
    }
    
    if (brandNames.length > 10) {
      throw ArgumentError('Too many brands (max 10)');
    }

    // Sanitiser tous les noms
    final sanitized = brandNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty && name.length <= 50)
        .toList();
    
    if (sanitized.isEmpty) {
      throw ArgumentError('No valid brand names provided');
    }

    // ✅ Requête avec JOIN et conditions OR
    var query = database.select(database.products).join([
      innerJoin(
        database.brands,
        database.brands.id.equalsExp(database.products.brandId),
      ),
    ]);
    
    // Construire condition OR pour plusieurs marques
    Expression<bool>? combinedCondition;
    for (final brandName in sanitized) {
      final condition = database.brands.name.like('%$brandName%');
      combinedCondition = combinedCondition == null ? condition : combinedCondition | condition;
    }
    
    if (combinedCondition != null) {
      query = query..where(combinedCondition);
    }
    
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }
    
    // Tri par marque puis par nom de produit
    query = query..orderBy([
      OrderingTerm.asc(database.brands.name),
      OrderingTerm.asc(database.products.name),
    ]);
    
    final results = await query.get();
    return results.map((result) => result.readTable(database.products)).toList();
  }

  Future<List<Product>> getProductsByBrandId(int brandId, {int? limit}) async {
    if (brandId <= 0) {
      throw ArgumentError('Brand ID must be positive');
    }
    
    // ✅ Requête simple par brandId (optimisée)
    var query = database.select(database.products);
    query = query..where((p) => p.brandId.equals(brandId));
    
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }

    query = query..orderBy([(p) => OrderingTerm.asc(p.name)]);

    return await query.get();
  }

  Future<List<Product>> getProductsByBrandIds(List<int> brandIds, {int? limit}) async {
    if (brandIds.isEmpty) {
      throw ArgumentError('Brand IDs list cannot be empty');
    }
    
    if (brandIds.length > 20) {
      throw ArgumentError('Too many brand IDs (max 20)');
    }
    
    final validIds = brandIds.where((id) => id > 0).toList();
    if (validIds.isEmpty) {
      throw ArgumentError('No valid brand IDs provided');
    }
    
    // ✅ Requête avec condition IN
    var query = database.select(database.products);
    query = query..where((p) => p.brandId.isIn(validIds));
    
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }

    query = query..orderBy([
      (p) => OrderingTerm.asc(p.brandId),
      (p) => OrderingTerm.asc(p.name),
    ]);
    
    return await query.get();
  }

  Future<List<Product>> getProductsByBarcodes(List<int> barcodes) async {
    if (barcodes.isEmpty) {
      throw ArgumentError('Barcodes list cannot be empty');
    }
    
    if (barcodes.length > 50) {
      throw ArgumentError('Too many barcodes (max 50)');
    }
    
    final validBarcodes = barcodes.where((barcode) => barcode > 0).toList();
    if (validBarcodes.isEmpty) {
      throw ArgumentError('No valid barcodes provided');
    }
    
    return await (database.select(database.products)
          ..where((p) => p.barcode.isIn(validBarcodes))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  // ✅ LOGIQUE COMPLEXE : Prix avec magasins
  Future<List<PriceWithStoreResult>> getCurrentPricesByProductId(int productId) async {
    if (productId <= 0) {
      throw ArgumentError('Product ID must be positive');
    }

    // ✅ Requête avec JOIN pour avoir magasin + prix
    final query = database.select(database.priceHistory).join([
      leftOuterJoin(
        database.supermarkets,
        database.supermarkets.id.equalsExp(database.priceHistory.supermarketId),
      ),
    ])
      ..where(database.priceHistory.productId.equals(productId))
      ..orderBy([OrderingTerm.desc(database.priceHistory.date)]);

    final results = await query.get();

    // ✅ LOGIQUE MÉTIER : Grouper par magasin (prix le plus récent par magasin)
    final Map<int, PriceWithStoreResult> latestByStore = {};
    for (final result in results) {
      final priceData = result.readTable(database.priceHistory);
      final storeData = result.readTableOrNull(database.supermarkets);
      final storeId = priceData.supermarketId;
      
      if (!latestByStore.containsKey(storeId)) {
        latestByStore[storeId] = PriceWithStoreResult(
          price: priceData,
          store: storeData,
        );
      }
    }

    return latestByStore.values.toList();
  }

  Future<List<PriceWithStoreResult>> getPriceHistoryByProductId(
    int productId, {
    String? storeFilter,
    DateTime? since,
    int limitDays = 30,
    List<String>? storeNames,
  }) async {
    if (productId <= 0) {
      throw ArgumentError('Product ID must be positive');
    }

    // ✅ Requête avec JOIN et filtres dynamiques
    var query = database.select(database.priceHistory).join([
      leftOuterJoin(
        database.supermarkets,
        database.supermarkets.id.equalsExp(database.priceHistory.supermarketId),
      ),
    ])
      ..where(database.priceHistory.productId.equals(productId));

    // Filtres temporels
    if (since != null) {
      query = query..where(database.priceHistory.date.isBiggerThanValue(since));
    } else if (limitDays > 0) {
      final limitDate = DateTime.now().subtract(Duration(days: limitDays));
      query = query..where(database.priceHistory.date.isBiggerThanValue(limitDate));
    }

    // Filtre par nom de magasin
    if (storeFilter != null && storeFilter.trim().isNotEmpty) {
      query = query..where(database.supermarkets.name.like('%${storeFilter.trim()}%'));
    }
    
    // Filtre par liste de magasins
    if (storeNames != null && storeNames.isNotEmpty) {
      final validNames = storeNames.where((name) => name.trim().isNotEmpty).toList();
      if (validNames.isNotEmpty) {
        Expression<bool>? storeCondition;
        for (final storeName in validNames) {
          final condition = database.supermarkets.name.like('%$storeName%');
          storeCondition = storeCondition == null ? condition : storeCondition | condition;
        }
        if (storeCondition != null) {
          query = query..where(storeCondition);
        }
      }
    }

    query = query..orderBy([OrderingTerm.asc(database.priceHistory.date)]);

    final results = await query.get();

    return results.map((result) {
      final priceData = result.readTable(database.priceHistory);
      final storeData = result.readTableOrNull(database.supermarkets);
      
      return PriceWithStoreResult(
        price: priceData,
        store: storeData,
      );
    }).toList();
  }

  // ✅ MARQUES : Recherche avancée
  Future<List<Brand>> searchBrandsByName(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }
    
    final sanitized = query.trim();
    if (sanitized.length > 50) {
      throw ArgumentError('Search query too long (max 50 characters)');
    }
    
    if (limit <= 0 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }
    
    return await (database.select(database.brands)
          ..where((b) => b.name.like('%$sanitized%'))
          ..limit(limit)
          ..orderBy([(b) => OrderingTerm.asc(b.name)]))
        .get();
  }

  Future<List<Brand>> getAllBrands() => database.getAllBrands();
}

// ✅ CLASSES de résultats métier
class PriceWithStoreResult {
  final PriceHistoryData price;
  final Supermarket? store;
  
  const PriceWithStoreResult({
    required this.price,
    this.store,
  });
}