import 'package:test/test.dart';
import 'package:shared_models/models/product/productdto.dart';
import '../../lib/data_database.dart';
import '../../lib/services/product_service.dart';
import 'package:data_server/services/image_service.dart';


void main() {
  group('ProductService', () {
    late DataDatabase database;
    late ImageService imageService;
    late ProductService service;

    setUp(() async {
      database = DataDatabase.forTesting();
      imageService = ImageService();
      service = ProductService(database, imageService);
    });

    tearDown(() async {
      await database.close();
    });

    test('should get all products as DTOs', () async {
      // Arrange
      await service.createProduct(ProductDto(
        barcode: 1111111111,
        name: 'Product 1',
      ));
      await service.createProduct(ProductDto(
        barcode: 2222222222,
        name: 'Product 2',
      ));

      // Act
      final products = await service.getAllProducts();

      // Assert
      expect(products.length, equals(2));
      expect(products.map((p) => p.name), containsAll(['Product 1', 'Product 2']));
    });

    test('should create product and return with ID', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'New Product',
        description: 'A new product',
      );

      // Act
      final created = await service.createProduct(dto);

      // Assert
      expect(created.id, isNotNull);
      expect(created.barcode, equals(1234567890));
      expect(created.name, equals('New Product'));
      expect(created.description, equals('A new product'));
    });

    test('should throw error when creating product with empty name', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: '',
      );

      // Act & Assert
      expect(
        () => service.createProduct(dto),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when creating product with duplicate barcode', () async {
      // Arrange
      final dto1 = ProductDto(
        barcode: 1234567890,
        name: 'Product 1',
      );
      final dto2 = ProductDto(
        barcode: 1234567890,
        name: 'Product 2',
      );

      // Act
      await service.createProduct(dto1);

      // Assert
      expect(
        () => service.createProduct(dto2),
        throwsA(isA<StateError>()),
      );
    });

    test('should get product by barcode', () async {
      // Arrange
      final created = await service.createProduct(ProductDto(
        barcode: 9876543210,
        name: 'Barcode Product',
      ));

      // Act
      final found = await service.getProductByBarcode(9876543210);

      // Assert
      expect(found, isNotNull);
      expect(found!.id, equals(created.id));
      expect(found.barcode, equals(9876543210));
    });

    test('should return null for non-existent barcode', () async {
      // Act
      final found = await service.getProductByBarcode(999999);

      // Assert
      expect(found, isNull);
    });

    test('should update product', () async {
      // Arrange
      final created = await service.createProduct(ProductDto(
        barcode: 1111111111,
        name: 'Original Name',
      ));

      final updated = created.copyWith(
        name: 'Updated Name',
        description: 'Updated description',
      );

      // Act
      final result = await service.updateProduct(updated);

      // Assert
      expect(result.id, equals(created.id));
      expect(result.name, equals('Updated Name'));
      expect(result.description, equals('Updated description'));
    });

    test('should throw error when updating product without ID', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'No ID Product',
      );

      // Act & Assert
      expect(
        () => service.updateProduct(dto),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should delete product', () async {
      // Arrange
      final created = await service.createProduct(ProductDto(
        barcode: 1234567890,
        name: 'To Delete',
      ));

      // Act
      await service.deleteProduct(created.id!);

      // Assert
      final found = await service.getProductByBarcode(1234567890);
      expect(found, isNull);
    });

    test('should search products', () async {
      // Arrange
      await service.createProduct(ProductDto(
        barcode: 1111111111,
        name: 'Apple iPhone',
      ));
      await service.createProduct(ProductDto(
        barcode: 2222222222,
        name: 'Samsung Galaxy',
      ));
      await service.createProduct(ProductDto(
        barcode: 3333333333,
        name: 'Apple iPad',
      ));

      // Act
      final appleProducts = await service.searchProducts('Apple');
      final samsungProducts = await service.searchProducts('Samsung');

      // Assert
      expect(appleProducts.length, equals(2));
      expect(samsungProducts.length, equals(1));
      expect(appleProducts.every((p) => p.name.contains('Apple')), isTrue);
    });

    test('should create product and return with image URL', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'New Product',
        description: 'A new product',
        imageFileName: 'test_image.jpg',
      );

      // Act
      final created = await service.createProduct(dto);

      // Assert
      expect(created.id, isNotNull);
      expect(created.barcode, equals(1234567890));
      expect(created.name, equals('New Product'));
      expect(created.description, equals('A new product'));
      expect(created.imageFileName, equals('test_image.jpg'));
      expect(created.imageUrl, equals('/api/images/compressed/test_image.jpg'));
    });

    test('should create product without image', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 9876543210,
        name: 'Product without image',
      );

      // Act
      final created = await service.createProduct(dto);

      // Assert
      expect(created.imageFileName, isNull);
      expect(created.imageUrl, isNull);
    });

    test('should get all products with image URLs', () async {
      // Arrange
      await service.createProduct(ProductDto(
        barcode: 1111111111,
        name: 'Product 1',
        imageFileName: 'image1.jpg',
      ));
      await service.createProduct(ProductDto(
        barcode: 2222222222,
        name: 'Product 2',
      ));

      // Act
      final products = await service.getAllProducts();

      // Assert
      expect(products.length, equals(2));

      final productWithImage = products.firstWhere((p) => p.name == 'Product 1');
      final productWithoutImage = products.firstWhere((p) => p.name == 'Product 2');

      expect(productWithImage.imageUrl, equals('/api/images/compressed/image1.jpg'));
      expect(productWithoutImage.imageUrl, isNull);
    });
  });
}