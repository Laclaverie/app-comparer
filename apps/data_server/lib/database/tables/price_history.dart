import 'package:drift/drift.dart';

class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  IntColumn get supermarketId => integer()();
  RealColumn get price => real()();
  RealColumn get originalPrice => real().nullable()(); // ✅ ESSENTIEL !
  DateTimeColumn get date => dateTime()();
  IntColumn get userId => integer().nullable()();
  BoolColumn get isPromotion => boolean().withDefault(const Constant(false))();
  TextColumn get promotionDescription => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}