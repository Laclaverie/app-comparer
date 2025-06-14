import 'package:test/test.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:shared_models/models/product/productdto.dart';
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
        imageFileName: const Value('test_image.jpg'),  // ← Corrigé
        imagePath: const Value('/server/path/test_image.jpg'),  // ← Corrigé
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
      expect(dto.imageFileName, equals('test_image.jpg'));  // ← Corrigé
      expect(dto.imageUrl, isNull);  // ← imageUrl n'est pas dans toDto()
      expect(dto.description, equals('Test description'));

      await database.close();
    });

    test('should convert Product to ProductDto with image URL', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      final companion = ProductsCompanion(
        barcode: const Value(9876543210),
        name: const Value('Product with Image'),
        imageFileName: const Value('compressed_image.jpg'),
      );

      final id = await database.insertProduct(companion);
      final product = await database.getProductById(id);

      // Act
      final dto = product!.toDtoWithImageUrl();  // ← Test de la nouvelle méthode

      // Assert
      expect(dto.id, equals(id));
      expect(dto.barcode, equals(9876543210));
      expect(dto.name, equals('Product with Image'));
      expect(dto.imageFileName, equals('compressed_image.jpg'));
      expect(dto.imageUrl, equals('/api/images/compressed/compressed_image.jpg'));  // ← URL générée

      await database.close();
    });

    test('should handle null imageFileName in toDtoWithImageUrl', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      final companion = ProductsCompanion(
        barcode: const Value(1111111111),
        name: const Value('Product without Image'),
        imageFileName: const Value.absent(),  // ← Pas d'image
      );

      final id = await database.insertProduct(companion);
      final product = await database.getProductById(id);

      // Act
      final dto = product!.toDtoWithImageUrl();

      // Assert
      expect(dto.imageFileName, isNull);
      expect(dto.imageUrl, isNull);  // ← Pas d'URL car pas d'image

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
        imageFileName: 'test_image.jpg',  // ← Corrigé
        imageUrl: '/api/images/compressed/test_image.jpg',  // ← Ajouté mais ignoré dans toCompanion
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
      expect(companion.imageFileName.present, isTrue);  // ← Corrigé
      expect(companion.imageFileName.value, equals('test_image.jpg'));  // ← Corrigé
      expect(companion.imagePath.present, isFalse);  // ← imagePath géré par le serveur
      expect(companion.description.present, isTrue);
      expect(companion.description.value, equals('Test description'));
    });

    test('should handle nullable fields in ProductDto to Companion conversion', () {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'Minimal Product',
        // Tous les autres champs sont null
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      expect(companion.id.present, isFalse);
      expect(companion.barcode.value, equals(1234567890));
      expect(companion.name.value, equals('Minimal Product'));
      expect(companion.brandId.present, isFalse);
      expect(companion.categoryId.present, isFalse);
      expect(companion.imageFileName.present, isFalse);  // ← Corrigé
      expect(companion.imagePath.present, isFalse);  // ← Ajouté
      expect(companion.description.present, isFalse);
    });

    test('should preserve imageUrl when converting from DTO but not store it in DB', () {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'Product with URL',
        imageFileName: 'image.jpg',
        imageUrl: '/api/images/compressed/image.jpg',  // ← URL fournie
        localImagePath: '/local/path/image.jpg',  // ← Chemin local
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      expect(companion.imageFileName.present, isTrue);
      expect(companion.imageFileName.value, equals('image.jpg'));
      expect(companion.imagePath.present, isFalse);  // ← imagePath n'est pas stocké depuis DTO
      
      // imageUrl et localImagePath ne sont pas dans la table
      // Ils sont calculés côté serveur/client
    });
  });
}