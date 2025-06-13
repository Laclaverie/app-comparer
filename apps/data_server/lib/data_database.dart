import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

part 'data_database.g.dart';
// TODO > improve because it's a copy of the shared_models package
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get barcode => integer().unique()();
  TextColumn get name => text()();
  IntColumn get brandId => integer().nullable().references(Brands, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get imageFileName => text().nullable()();  // ← Nom du fichier, pas URL
  TextColumn get imagePath => text().nullable()();      // ← Chemin local sur serveur
  TextColumn get description => text().nullable()();
}

class Brands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get parentCategoryId => integer().nullable().references(Categories, #id)();
}

class Supermarkets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
}

class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get supermarketId => integer().references(Supermarkets, #id)();
  RealColumn get price => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  BoolColumn get isPromotion => boolean().withDefault(const Constant(false))();
  TextColumn get promotionDescription => text().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
}


@DriftDatabase(
  tables: [Products, Brands, Categories, Supermarkets, PriceHistory, Users],
)
class DataDatabase extends _$DataDatabase {
  // Constructeur pour la production
  DataDatabase() : super(_openConnection('database.db'));
  
  // Constructeur pour les tests
  DataDatabase.forTesting() : super(_openConnection(':memory:'));
  
  // Constructeur pour le développement avec fichier persistant
  DataDatabase.development() : super(_openConnection('dev_database.db'));

  @override
  int get schemaVersion => 1;

  // Méthode statique pour créer la connexion
  static QueryExecutor _openConnection(String path) {
    if (path == ':memory:') {
      return NativeDatabase.memory();
    }
    return NativeDatabase.createInBackground(File(path));
  }

  // ✅ Supprimez la méthode openConnection() - plus besoin

  // ✅ Méthodes existantes
  Future<List<Product>> getAllProducts() async {
    return await select(products).get();
  }

  Future<Product?> getProductByBarcode(int barcode) async {
    return await (select(products)
          ..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion product) async {
    return await into(products).insert(product);
  }

  Future<Product?> getProductById(int id) async {
    return await (select(products)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
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

}