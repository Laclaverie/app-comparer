import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/models/database/tables_product.dart'; // ← Import des tables partagées

part 'app_database.g.dart';

const String databaseName = 'app_database.sqlite';

// --- Database class utilisant les tables partagées ---
@DriftDatabase(
  tables: [Products, Brands, Categories, Supermarkets, PriceHistory, Users],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  factory AppDatabase.forTesting() {
    return AppDatabase._internal(NativeDatabase.memory());
  }

  AppDatabase._internal(super.e);

  @override
  int get schemaVersion => 1;

  // --- Méthodes spécifiques à l'app mobile ---
  Future<List<Product>> getAllProducts() async {
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

  // Méthodes pour l'offline-first mobile
  Future<List<PriceHistoryData>> getRecentPrices(int productId) async {
    return await (select(priceHistory)
          ..where((p) => p.productId.equals(productId))
          ..orderBy([(p) => OrderingTerm.desc(p.date)])
          ..limit(10))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, databaseName);
    return SqfliteQueryExecutor(
      path: dbPath,
      logStatements: true,
    );
  });
}