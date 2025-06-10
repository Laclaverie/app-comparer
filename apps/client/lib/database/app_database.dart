import 'package:drift/drift.dart';
import 'package:drift/native.dart'show NativeDatabase;
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

const String databaseName = 'app_database.sqlite';

// --- Table definitions ---

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get barcode => integer().unique()();
  TextColumn get name => text()();
  IntColumn get brandId => integer().nullable().references(Brands, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get imageUrl => text().nullable()();
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

// --- Database class ---

@DriftDatabase(
  tables: [Products, Brands, Categories, Supermarkets, PriceHistory, Users],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Add this factory for testing
  factory AppDatabase.forTesting() {
    return AppDatabase._internal(NativeDatabase.memory());
  }

  AppDatabase._internal(super.e);

  @override
  int get schemaVersion => 1;
}

// --- Open connection helper ---

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, databaseName);
    // Let Drift open the encrypted database using SqfliteQueryExecutor
    return SqfliteQueryExecutor(
      path: dbPath,
      logStatements: true,
    );
  });
}