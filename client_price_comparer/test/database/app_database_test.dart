import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:client_price_comparer/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Use an in-memory database for testing
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and query product', () async {
    final id = await db.into(db.products).insert(ProductsCompanion(
      barcode: Value(1234567890123),
      name: Value('Test Product'),
    ));

    final product = await db.select(db.products).getSingle();
    expect(product.id, id);
    expect(product.barcode, 1234567890123);
    expect(product.name, 'Test Product');
  });
}