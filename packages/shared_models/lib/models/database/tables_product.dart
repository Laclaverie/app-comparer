import 'package:drift/drift.dart';

/// Table des produits avec cache intelligent
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // ✅ COHÉRENT avec ProductDto
  IntColumn get barcode => integer()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get brandId => integer().nullable().references(Brands, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)(); 
  TextColumn get imageFileName => text().nullable()(); 
  TextColumn get imageUrl => text().nullable()();
  TextColumn get localImagePath => text().nullable()();  // ✅ Ajouté (spécifique client)
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  // Champs de base
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // 🎯 CHAMPS SPÉCIFIQUES CLIENT (cache/tracking)
  DateTimeColumn get lastScannedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isCachedLocally => boolean().withDefault(const Constant(false))();
  IntColumn get cacheVersion => integer().withDefault(const Constant(1))();
  IntColumn get scanCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstSeenAt => dateTime().nullable()();
}

/// Table des marques
class Brands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get logoUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des catégories  
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des supermarchés
class Supermarkets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table de l'historique des prix
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get supermarketId => integer().references(Supermarkets, #id)();
  RealColumn get price => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  
  // Support des promotions
  BoolColumn get isPromotion => boolean().withDefault(const Constant(false))();
  TextColumn get promotionDescription => text().nullable()();
  RealColumn get originalPrice => real().nullable()();
  
  // Métadonnées
  TextColumn get source => text().withDefault(const Constant('manual'))();
  BoolColumn get isValidated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des utilisateurs
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastActiveAt => dateTime().nullable()();
}