import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'database/tables/tables.dart';

part 'data_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Brands,
    Categories,
    Supermarkets,
    PriceHistory,
    Users,
  ],
)
class DataDatabase extends _$DataDatabase {
  DataDatabase() : super(_openConnection('database.db'));
  DataDatabase.forTesting() : super(_openConnection(':memory:'));
  DataDatabase.development() : super(_openConnection('dev_database.db'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        try {
          await m.addColumn(priceHistory, priceHistory.originalPrice);
          print('✅ Added originalPrice column');
        } catch (e) {
          print('Column originalPrice already exists: $e');
        }
      }
    },
  );

  static QueryExecutor _openConnection(String path) {
    if (path == ':memory:') {
      return NativeDatabase.memory();
    }
    return NativeDatabase.createInBackground(File(path));
  }

  // ✅ PRODUCTS - CRUD de base uniquement
  Future<List<Product>> getAllProducts() async {
    return await select(products).get();
  }

  Future<Product?> getProductByBarcode(int barcode) async {
    try {
      print('🔍 DB DEBUG: Searching for barcode: $barcode');
      
      // ✅ SYNTAXE ALTERNATIVE : Chaînage simple
      final query = select(products)
          ..where((p) => p.barcode.equals(barcode));
      
      final result = await query.getSingleOrNull();
      
      print('🔍 DB DEBUG: Found product: ${result?.name ?? 'NULL'}');
      return result;
    } catch (e, stackTrace) {
      print('❌ DB ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> insertProduct(ProductsCompanion product) async {
    return await into(products).insert(product);
  }

  Future<bool> updateProduct(ProductsCompanion product) async {
    return await update(products).replace(product);
  }

  Future<int> deleteProduct(int id) async {
    return await (delete(products)
          ..where((p) => p.id.equals(id)))
        .go();
  }

  Future<List<Product>> searchProducts(String query) async {
    return await (select(products)
          ..where((p) => p.name.like('%$query%')))
        .get();
  }

  Future<List<PriceHistoryData>> getPriceHistoryForProduct(int productId) async {
    return await (select(priceHistory)
          ..where((p) => p.productId.equals(productId))
          ..orderBy([(p) => OrderingTerm.desc(p.date)]))
        .get();
  }

  Future<List<Brand>> getAllBrands() async {
    return await select(brands).get();
  }

  Future<List<Category>> getAllCategories() async {
    return await select(categories).get();
  }

  Future<List<Supermarket>> getAllSupermarkets() async {
    return await select(supermarkets).get();
  }

  Future<List<User>> getAllUsers() async {
    return await select(users).get();
  }

  Future<void> fixProductsData() async {
    try {
      print('🔧 Fixing products data...');
      
      // Corriger les colonnes NULL avec les valeurs par défaut
      final updatedRows = await customUpdate(
        '''
        UPDATE products 
        SET 
          is_active = COALESCE(is_active, 1),
          created_at = COALESCE(created_at, datetime('now')),
          updated_at = COALESCE(updated_at, datetime('now'))
        WHERE 
          is_active IS NULL 
          OR created_at IS NULL
        ''',
      );
      
      print('✅ Fixed $updatedRows products with NULL values');
      
      // Vérification
      final nullCount = await customSelect(
        '''
        SELECT COUNT(*) as count 
        FROM products 
        WHERE is_active IS NULL OR created_at IS NULL
        '''
      ).getSingle();
      
      print('🔍 Products with NULL values remaining: ${nullCount.data['count']}');
      
    } catch (e) {
      print('❌ Error fixing products data: $e');
      rethrow;
    }
  }

  Future<void> debugTableSchema() async {
  try {
    print('🔍 Current products table schema:');
    final schema = await customSelect('PRAGMA table_info(products)').get();
    
    print('📋 Existing columns:');
    for (final row in schema) {
      final data = row.data;
      print('  - ${data['name']} (${data['type']}) nullable:${data['notnull'] == 0}');
    }
    
    // Vérifier si les colonnes manquantes existent
    final columnNames = schema.map((row) => row.data['name'] as String).toList();
    
    final expectedColumns = ['is_active', 'created_at', 'updated_at'];
    for (final col in expectedColumns) {
      if (!columnNames.contains(col)) {
        print('❌ Missing column: $col');
      } else {
        print('✅ Found column: $col');
      }
    }
    
  } catch (e) {
    print('❌ Schema debug error: $e');
  }
}
}