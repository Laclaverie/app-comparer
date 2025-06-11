import 'package:test/test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import '../../lib/data_database.dart';

void main() {
  group('DataDatabase', () {
    late DataDatabase database;

    setUp(() async {
      // Utilise une base en mémoire pour les tests
      database = DataDatabase.forTesting();
    });

    tearDown(() async {
      await database.close();
    });

    group('Products', () {
      test('should insert and retrieve product', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(1234567890),
          name: const Value('Test Product'),
          description: const Value('A test product'),
        );

        // Act
        final id = await database.insertProduct(productCompanion);
        final retrievedProduct = await database.getProductById(id);

        // Assert
        expect(retrievedProduct, isNotNull);
        expect(retrievedProduct!.id, equals(id));
        expect(retrievedProduct.barcode, equals(1234567890));
        expect(retrievedProduct.name, equals('Test Product'));
        expect(retrievedProduct.description, equals('A test product'));
      });

      test('should get product by barcode', () async {
        // Arrange
        final barcode = 9876543210;
        final productCompanion = ProductsCompanion(
          barcode: Value(barcode),
          name: const Value('Barcode Product'),
        );

        // Act
        await database.insertProduct(productCompanion);
        final product = await database.getProductByBarcode(barcode);

        // Assert
        expect(product, isNotNull);
        expect(product!.barcode, equals(barcode));
        expect(product.name, equals('Barcode Product'));
      });

      test('should return null when product not found by barcode', () async {
        // Act
        final product = await database.getProductByBarcode(999999);

        // Assert
        expect(product, isNull);
      });

      test('should update product', () async {
        // Arrange
        final originalCompanion = ProductsCompanion(
          barcode: const Value(1111111111),
          name: const Value('Original Name'),
        );
        final id = await database.insertProduct(originalCompanion);

        final updatedCompanion = ProductsCompanion(
          id: Value(id),
          barcode: const Value(1111111111),
          name: const Value('Updated Name'),
          description: const Value('Updated description'),
        );

        // Act
        final updated = await database.updateProduct(updatedCompanion);
        final retrievedProduct = await database.getProductById(id);

        // Assert
        expect(updated, isTrue);
        expect(retrievedProduct!.name, equals('Updated Name'));
        expect(retrievedProduct.description, equals('Updated description'));
      });

      test('should delete product', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(2222222222),
          name: const Value('To Delete'),
        );
        final id = await database.insertProduct(productCompanion);

        // Act
        final deletedCount = await database.deleteProduct(id);
        final retrievedProduct = await database.getProductById(id);

        // Assert
        expect(deletedCount, equals(1));
        expect(retrievedProduct, isNull);
      });

      test('should search products by name', () async {
        // Arrange
        await database.insertProduct(ProductsCompanion(
          barcode: const Value(3333333333),
          name: const Value('Apple iPhone'),
        ));
        await database.insertProduct(ProductsCompanion(
          barcode: const Value(4444444444),
          name: const Value('Samsung Galaxy'),
        ));
        await database.insertProduct(ProductsCompanion(
          barcode: const Value(5555555555),
          name: const Value('Apple iPad'),
        ));

        // Act
        final appleProducts = await database.searchProducts('Apple');
        final samsungProducts = await database.searchProducts('Samsung');

        // Assert
        expect(appleProducts.length, equals(2));
        expect(samsungProducts.length, equals(1));
        expect(appleProducts.every((p) => p.name.contains('Apple')), isTrue);
        expect(samsungProducts.first.name.contains('Samsung'), isTrue);
      });

      test('should get all products', () async {
        // Arrange
        await database.insertProduct(ProductsCompanion(
          barcode: const Value(1111111111),
          name: const Value('Product 1'),
        ));
        await database.insertProduct(ProductsCompanion(
          barcode: const Value(2222222222),
          name: const Value('Product 2'),
        ));

        // Act
        final products = await database.getAllProducts();

        // Assert
        expect(products.length, equals(2));
      });
    });

    group('Brands', () {
      test('should get all brands', () async {
        // Arrange
        await database.into(database.brands).insert(BrandsCompanion(
          name: const Value('Apple'),
        ));
        await database.into(database.brands).insert(BrandsCompanion(
          name: const Value('Samsung'),
        ));

        // Act
        final brands = await database.getAllBrands();

        // Assert
        expect(brands.length, equals(2));
        expect(brands.map((b) => b.name), containsAll(['Apple', 'Samsung']));
      });
    });

    group('Categories', () {
      test('should get all categories', () async {
        // Arrange
        await database.into(database.categories).insert(CategoriesCompanion(
          name: const Value('Electronics'),
        ));
        await database.into(database.categories).insert(CategoriesCompanion(
          name: const Value('Books'),
        ));

        // Act
        final categories = await database.getAllCategories();

        // Assert
        expect(categories.length, equals(2));
        expect(categories.map((c) => c.name), containsAll(['Electronics', 'Books']));
      });
    });
  });
}