import 'package:test/test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import '../../lib/data_database.dart';

void main() {
  group('DataDatabase', () {
    late DataDatabase database;

    setUp(() async {
      database = DataDatabase.forTesting();
    });

    tearDown(() async {
      await database.close();
    });

    group('Products', () {
      test('should insert and retrieve product with image fields', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(1234567890),
          name: const Value('Test Product'),
          description: const Value('A test product'),
          imageFileName: const Value('test_image.jpg'),  // ← Ajouté
          imagePath: const Value('/server/images/test_image.jpg'),  // ← Ajouté
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
        expect(retrievedProduct.imageFileName, equals('test_image.jpg'));  // ← Ajouté
        expect(retrievedProduct.imagePath, equals('/server/images/test_image.jpg'));  // ← Ajouté
      });

      test('should handle null image fields', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(9876543210),
          name: const Value('Product without image'),
          imageFileName: const Value.absent(),  // ← Explicitement absent
          imagePath: const Value.absent(),  // ← Explicitement absent
        );

        // Act
        final id = await database.insertProduct(productCompanion);
        final retrievedProduct = await database.getProductById(id);

        // Assert
        expect(retrievedProduct, isNotNull);
        expect(retrievedProduct!.imageFileName, isNull);
        expect(retrievedProduct.imagePath, isNull);
      });

      test('should update product with new image', () async {
        // Arrange
        final originalCompanion = ProductsCompanion(
          barcode: const Value(1111111111),
          name: const Value('Original Name'),
          imageFileName: const Value.absent(),
        );
        final id = await database.insertProduct(originalCompanion);

        final updatedCompanion = ProductsCompanion(
          id: Value(id),
          barcode: const Value(1111111111),
          name: const Value('Updated Name'),
          description: const Value('Updated description'),
          imageFileName: const Value('new_image.jpg'),  // ← Nouvelle image
          imagePath: const Value('/server/images/new_image.jpg'),
        );

        // Act
        final updated = await database.updateProduct(updatedCompanion);
        final retrievedProduct = await database.getProductById(id);

        // Assert
        expect(updated, isTrue);
        expect(retrievedProduct!.name, equals('Updated Name'));
        expect(retrievedProduct.description, equals('Updated description'));
        expect(retrievedProduct.imageFileName, equals('new_image.jpg'));
        expect(retrievedProduct.imagePath, equals('/server/images/new_image.jpg'));
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