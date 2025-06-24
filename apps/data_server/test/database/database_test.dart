import 'package:sqlite3/sqlite3.dart' show SqliteException;
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

    group('Products - Barcode Only', () {
      test('should insert and retrieve product by barcode with image fields', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(1234567890),
          name: const Value('Test Product'),
          description: const Value('A test product'),
          imageFileName: const Value('test_image.jpg'),
          imageUrl: const Value('/server/images/test_image.jpg'),
        );

        // Act
        final id = await database.insertProduct(productCompanion);
        // ✅ CHANGEMENT : Récupérer par BARCODE au lieu d'ID
        final retrievedProduct = await database.getProductByBarcode(1234567890);

        // Assert
        expect(retrievedProduct, isNotNull);
        expect(retrievedProduct!.id, equals(id));
        expect(retrievedProduct.barcode, equals(1234567890));
        expect(retrievedProduct.name, equals('Test Product'));
        expect(retrievedProduct.description, equals('A test product'));
        expect(retrievedProduct.imageFileName, equals('test_image.jpg'));
        expect(retrievedProduct.imageUrl, equals('/server/images/test_image.jpg'));
      });

      test('should handle null image fields when retrieving by barcode', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(9876543210),
          name: const Value('Product without image'),
          imageFileName: const Value.absent(),
          imageUrl: const Value.absent(),
        );

        // Act
        await database.insertProduct(productCompanion);
        // ✅ CHANGEMENT : Récupérer par BARCODE
        final retrievedProduct = await database.getProductByBarcode(9876543210);

        // Assert
        expect(retrievedProduct, isNotNull);
        expect(retrievedProduct!.barcode, equals(9876543210));
        expect(retrievedProduct.imageFileName, isNull);
        expect(retrievedProduct.imageUrl, isNull);
      });

      test('should update product by barcode with new image', () async {
        // Arrange
        final originalCompanion = ProductsCompanion(
          barcode: const Value(1111111111),
          name: const Value('Original Name'),
          imageFileName: const Value.absent(),
        );
        
        await database.insertProduct(originalCompanion);

        // ✅ CHANGEMENT : Récupérer le produit par BARCODE pour l'update
        final existingProduct = await database.getProductByBarcode(1111111111);
        expect(existingProduct, isNotNull);

        final updatedCompanion = ProductsCompanion(
          id: Value(existingProduct!.id),  // ✅ Utiliser l'ID existant
          barcode: const Value(1111111111),
          name: const Value('Updated Name'),
          description: const Value('Updated description'),
          imageFileName: const Value('new_image.jpg'),
          imageUrl: const Value('/server/images/new_image.jpg'),
        );

        // Act
        final updated = await database.updateProduct(updatedCompanion);
        // ✅ CHANGEMENT : Vérifier par BARCODE
        final retrievedProduct = await database.getProductByBarcode(1111111111);

        // Assert
        expect(updated, isTrue);
        expect(retrievedProduct!.name, equals('Updated Name'));
        expect(retrievedProduct.description, equals('Updated description'));
        expect(retrievedProduct.imageFileName, equals('new_image.jpg'));
        expect(retrievedProduct.imageUrl, equals('/server/images/new_image.jpg'));
      });

      test('should delete product by barcode', () async {
        // Arrange
        final productCompanion = ProductsCompanion(
          barcode: const Value(2222222222),
          name: const Value('To Delete'),
        );
        
        await database.insertProduct(productCompanion);

        // ✅ CHANGEMENT : Récupérer par BARCODE pour avoir l'ID interne
        final productToDelete = await database.getProductByBarcode(2222222222);
        expect(productToDelete, isNotNull);

        // Act
        final deletedCount = await database.deleteProduct(productToDelete!.id);
        // ✅ CHANGEMENT : Vérifier par BARCODE
        final retrievedProduct = await database.getProductByBarcode(2222222222);

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

      // ✅ NOUVEAU : Tests spécifiques aux barcodes
      test('should find product by barcode', () async {
        // Arrange
        const testBarcode = 1234567890;
        final productCompanion = ProductsCompanion(
          barcode: const Value(testBarcode),
          name: const Value('Barcode Test Product'),
        );
        await database.insertProduct(productCompanion);

        // Act
        final foundProduct = await database.getProductByBarcode(testBarcode);

        // Assert
        expect(foundProduct, isNotNull);
        expect(foundProduct!.barcode, equals(testBarcode));
        expect(foundProduct.name, equals('Barcode Test Product'));
      });

      test('should return null for non-existent barcode', () async {
        // Act
        final nonExistentProduct = await database.getProductByBarcode(9999999999);

        // Assert
        expect(nonExistentProduct, isNull);
      });

      test('should prevent duplicate barcodes', () async {
        // Arrange
        const duplicateBarcode = 1111111111;
        final firstProduct = ProductsCompanion(
          barcode: const Value(duplicateBarcode),
          name: const Value('First Product'),
        );
        final secondProduct = ProductsCompanion(
          barcode: const Value(duplicateBarcode),
          name: const Value('Second Product'),
        );

        // Act & Assert
        await database.insertProduct(firstProduct);
        
        // ✅ Doit lever une erreur de contrainte UNIQUE
        expect(
          () => database.insertProduct(secondProduct),
          throwsA(isA<SqliteException>()),
        );
      });

      // ✅ NOUVEAU : Test du workflow complet par barcode
      test('should handle complete CRUD operations by barcode', () async {
        const testBarcode = 7777777777;
        
        // CREATE
        final createCompanion = ProductsCompanion(
          barcode: const Value(testBarcode),
          name: const Value('CRUD Test Product'),
          description: const Value('Initial description'),
        );
        await database.insertProduct(createCompanion);

        // READ
        var product = await database.getProductByBarcode(testBarcode);
        expect(product, isNotNull);
        expect(product!.name, equals('CRUD Test Product'));

        // UPDATE
        final updateCompanion = ProductsCompanion(
          id: Value(product.id),
          barcode: const Value(testBarcode),
          name: const Value('Updated CRUD Product'),
          description: const Value('Updated description'),
          imageFileName: const Value('updated_image.jpg'),
        );
        await database.updateProduct(updateCompanion);

        // READ after UPDATE
        product = await database.getProductByBarcode(testBarcode);
        expect(product!.name, equals('Updated CRUD Product'));
        expect(product.description, equals('Updated description'));
        expect(product.imageFileName, equals('updated_image.jpg'));

        // DELETE
        await database.deleteProduct(product.id);

        // READ after DELETE
        final deletedProduct = await database.getProductByBarcode(testBarcode);
        expect(deletedProduct, isNull);
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

    // ✅ NOUVEAU : Tests de prix par barcode
    group('Price History by Barcode', () {
      test('should get price history for product by barcode', () async {
        // Arrange - Créer un produit
        const testBarcode = 8888888888;
        final productCompanion = ProductsCompanion(
          barcode: const Value(testBarcode),
          name: const Value('Price Test Product'),
        );
        final productId = await database.insertProduct(productCompanion);

        // Créer un magasin
        final storeCompanion = SupermarketsCompanion(
          name: const Value('Test Store'),
          address: const Value('Test Address'),
          city: const Value('Test City'),
        );
        final storeId = await database.into(database.supermarkets).insert(storeCompanion);

        // Créer des prix
        final priceCompanion = PriceHistoryCompanion(
          productId: Value(productId),
          supermarketId: Value(storeId),
          price: const Value(19.99),
          date: Value(DateTime.now()),
        );
        await database.into(database.priceHistory).insert(priceCompanion);

        // Act
        final product = await database.getProductByBarcode(testBarcode);
        expect(product, isNotNull);
        
        final priceHistory = await database.getPriceHistoryForProduct(product!.id);

        // Assert
        expect(priceHistory.length, equals(1));
        expect(priceHistory.first.price, equals(19.99));
        expect(priceHistory.first.productId, equals(productId));
      });
    });
  });
}