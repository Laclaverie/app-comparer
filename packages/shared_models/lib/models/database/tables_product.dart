import 'package:drift/drift.dart';

// --- Tables déplacées depuis app_database.dart ---

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