import 'package:test/test.dart';
import 'package:drift/drift.dart';
import 'package:shared_models/productdto.dart';
import '../../lib/data_database.dart';
import '../../lib/extensions/product_extensions.dart';

void main() {
  group('ProductExtensions', () {
    test('should convert Product to ProductDto', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      final companion = ProductsCompanion(
        barcode: const Value(1234567890),
        name: const Value('Test Product'),
        brandId: const Value(1),
        categoryId: const Value(2),
        imageUrl: const Value('https://example.com/image.jpg'),
        description: const Value('Test description'),
      );

      final id = await database.insertProduct(companion);
      final product = await database.getProductById(id);

      // Act
      final dto = product!.toDto();

      // Assert
      expect(dto.id, equals(id));
      expect(dto.barcode, equals(1234567890));
      expect(dto.name, equals('Test Product'));
      expect(dto.brandId, equals(1));
      expect(dto.categoryId, equals(2));
      expect(dto.imageUrl, equals('https://example.com/image.jpg'));
      expect(dto.description, equals('Test description'));

      await database.close();
    });

    test('should convert ProductDto to ProductsCompanion', () {
      // Arrange
      final dto = ProductDto(
        id: 1,
        barcode: 1234567890,
        name: 'Test Product',
        brandId: 1,
        categoryId: 2,
        imageUrl: 'https://example.com/image.jpg',
        description: 'Test description',
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      expect(companion.id.present, isTrue);
      expect(companion.id.value, equals(1));
      expect(companion.barcode.value, equals(1234567890));
      expect(companion.name.value, equals('Test Product'));
      expect(companion.brandId.present, isTrue);
      expect(companion.brandId.value, equals(1));
      expect(companion.categoryId.present, isTrue);
      expect(companion.categoryId.value, equals(2));
      expect(companion.imageUrl.present, isTrue);
      expect(companion.imageUrl.value, equals('https://example.com/image.jpg'));
      expect(companion.description.present, isTrue);
      expect(companion.description.value, equals('Test description'));
    });

    test('should handle nullable fields in ProductDto to Companion conversion', () {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'Minimal Product',
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      expect(companion.id.present, isFalse);
      expect(companion.barcode.value, equals(1234567890));
      expect(companion.name.value, equals('Minimal Product'));
      expect(companion.brandId.present, isFalse);
      expect(companion.categoryId.present, isFalse);
      expect(companion.imageUrl.present, isFalse);
      expect(companion.description.present, isFalse);
    });
  });
}