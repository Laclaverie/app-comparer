import 'package:drift/drift.dart';

/// Table des produits avec cache intelligent
@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get barcode => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  
  // ✅ CORRECTION : Ces champs doivent être nullable OU avoir des valeurs par défaut
  IntColumn get brandId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  
  TextColumn get imageUrl => text().nullable()();
  TextColumn get localImagePath => text().nullable()();
  
  // ✅ CRITIQUE : Ces champs DOIVENT avoir des valeurs par défaut
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isCachedLocally => boolean().withDefault(const Constant(false))();
  
  // ✅ CRITIQUE : Ces champs DOIVENT avoir des valeurs par défaut
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  // ✅ Ces champs peuvent être null
  DateTimeColumn get lastScannedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  // ✅ CRITIQUE : Ce champ DOIT avoir une valeur par défaut
  IntColumn get scanCount => integer().withDefault(const Constant(0))();
}

/// Table des marques
@DataClassName('Brand')
class Brands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  // ✅ AJOUT : Champs manquants avec valeurs par défaut
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des catégories  
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().nullable()();
  // ✅ AJOUT : Champs manquants avec valeurs par défaut
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des supermarchés
@DataClassName('Supermarket')
class Supermarkets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get postalCode => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get website => text().nullable()();
  
  // ✅ CRITIQUE : Ces champs DOIVENT avoir des valeurs par défaut
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table de l'historique des prix
@DataClassName('PriceHistoryData')
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get supermarketId => integer().references(Supermarkets, #id)();
  RealColumn get price => real()();
  DateTimeColumn get date => dateTime()();
  
  // ✅ Ces champs doivent avoir des valeurs par défaut
  BoolColumn get isPromotion => boolean().withDefault(const Constant(false))();
  TextColumn get promotionDescription => text().nullable()();
  RealColumn get originalPrice => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  BoolColumn get isValidated => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table des utilisateurs (copiée depuis shared_models)
@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get name => text()();
  
  // ✅ AJOUT : Champs avec valeurs par défaut pour éviter les erreurs null
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isEmailVerified => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastActiveAt => dateTime().nullable()();
}