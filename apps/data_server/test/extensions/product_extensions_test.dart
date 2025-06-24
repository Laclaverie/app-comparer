import 'package:test/test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:shared_models/models/product/productdto.dart';
import '../../lib/data_database.dart';
import '../../lib/extensions/product_extensions.dart';

void main() {
  group('ProductExtensions', () {
    test('should convert Product to ProductDto by barcode', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const testBarcode = 1234567890;
      
      final companion = ProductsCompanion(
        barcode: const Value(testBarcode),
        name: const Value('Test Product'),
        brandId: const Value(1),
        categoryId: const Value(2),
        imageFileName: const Value('test_image.jpg'),
        imageUrl: const Value('/server/path/test_image.jpg'),
        description: const Value('Test description'),
      );

      await database.insertProduct(companion);
      // ✅ CHANGEMENT : Récupérer par BARCODE au lieu d'ID
      final product = await database.getProductByBarcode(testBarcode);

      // Act
      final dto = product!.toDto();

      // Assert
      expect(dto.barcode, equals(testBarcode));  // ✅ Barcode comme identifiant principal
      expect(dto.name, equals('Test Product'));
      expect(dto.brandId, equals(1));
      expect(dto.categoryId, equals(2));
      expect(dto.imageFileName, equals('test_image.jpg'));
      expect(dto.imageUrl, isNull);  // ← imageUrl n'est pas dans toDto()
      expect(dto.description, equals('Test description'));

      await database.close();
    });

    test('should convert Product to ProductDto with image URL by barcode', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const testBarcode = 9876543210;
      
      final companion = ProductsCompanion(
        barcode: const Value(testBarcode),
        name: const Value('Product with Image'),
        imageFileName: const Value('compressed_image.jpg'),
      );

      await database.insertProduct(companion);
      // ✅ CHANGEMENT : Récupérer par BARCODE
      final product = await database.getProductByBarcode(testBarcode);

      // Act
      final dto = product!.toDtoWithImageUrl();  // ← Test de la nouvelle méthode

      // Assert
      expect(dto.barcode, equals(testBarcode));  // ✅ Barcode comme identifiant
      expect(dto.name, equals('Product with Image'));
      expect(dto.imageFileName, equals('compressed_image.jpg'));
      expect(dto.imageUrl, equals('/api/images/compressed/compressed_image.jpg'));  // ← URL générée

      await database.close();
    });

    test('should handle null imageFileName in toDtoWithImageUrl by barcode', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const testBarcode = 1111111111;
      
      final companion = ProductsCompanion(
        barcode: const Value(testBarcode),
        name: const Value('Product without Image'),
        imageFileName: const Value.absent(),  // ← Pas d'image
      );

      await database.insertProduct(companion);
      // ✅ CHANGEMENT : Récupérer par BARCODE
      final product = await database.getProductByBarcode(testBarcode);

      // Act
      final dto = product!.toDtoWithImageUrl();

      // Assert
      expect(dto.barcode, equals(testBarcode));  // ✅ Barcode comme identifiant
      expect(dto.imageFileName, isNull);
      expect(dto.imageUrl, isNull);  // ← Pas d'URL car pas d'image

      await database.close();
    });

    test('should convert ProductDto to ProductsCompanion without ID dependency', () {
      // Arrange
      // ✅ CHANGEMENT : DTO sans ID, barcode comme identifiant principal
      final dto = ProductDto(
        barcode: 1234567890,  // ✅ Barcode = identifiant principal
        name: 'Test Product',
        brandId: 1,
        categoryId: 2,
        imageFileName: 'test_image.jpg',
        imageUrl: '/api/images/compressed/test_image.jpg',  // ← Ignoré dans toCompanion
        description: 'Test description',
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      // ✅ CHANGEMENT : Plus de test sur ID, focus sur barcode
      expect(companion.barcode.value, equals(1234567890));
      expect(companion.name.value, equals('Test Product'));
      expect(companion.brandId.present, isTrue);
      expect(companion.brandId.value, equals(1));
      expect(companion.categoryId.present, isTrue);
      expect(companion.categoryId.value, equals(2));
      expect(companion.imageFileName.present, isTrue);
      expect(companion.imageFileName.value, equals('test_image.jpg'));
      expect(companion.imageUrl.present, isFalse);  // ✅ imageUrl n'est jamais stocké depuis DTO
      expect(companion.description.present, isTrue);
      expect(companion.description.value, equals('Test description'));
    });

    test('should handle nullable fields in ProductDto to Companion conversion', () {
      // Arrange
      // ✅ CHANGEMENT : DTO minimal avec uniquement barcode et name
      final dto = ProductDto(
        barcode: 1234567890,  // ✅ Barcode obligatoire
        name: 'Minimal Product',
        // Tous les autres champs sont null
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      // ✅ CHANGEMENT : Focus sur barcode au lieu d'ID
      expect(companion.barcode.value, equals(1234567890));
      expect(companion.name.value, equals('Minimal Product'));
      expect(companion.brandId.present, isFalse);
      expect(companion.categoryId.present, isFalse);
      expect(companion.imageFileName.present, isFalse);
      expect(companion.imageUrl.present, isFalse);
      expect(companion.description.present, isFalse);
    });

    test('should preserve imageUrl when converting from DTO but not store it in DB', () {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,  // ✅ Barcode comme identifiant
        name: 'Product with URL',
        imageFileName: 'image.jpg',
        imageUrl: '/api/images/compressed/image.jpg',  // ← URL fournie
        localImagePath: '/local/path/image.jpg',  // ← Chemin local
      );

      // Act
      final companion = dto.toCompanion();

      // Assert
      expect(companion.barcode.value, equals(1234567890));  // ✅ Barcode vérifié
      expect(companion.imageFileName.present, isTrue);
      expect(companion.imageFileName.value, equals('image.jpg'));
      expect(companion.imageUrl.present, isFalse);  // ← imageUrl n'est pas stocké depuis DTO
    });

    // ✅ NOUVEAU : Test du workflow complet par barcode
    test('should handle complete product workflow by barcode', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const testBarcode = 5555555555;

      // CREATE - Créer produit
      final createDto = ProductDto(
        barcode: testBarcode,
        name: 'Workflow Test Product',
        description: 'Initial description',
      );
      
      final companion = createDto.toCompanion();
      await database.insertProduct(companion);

      // READ - Lire par barcode et convertir en DTO
      final product = await database.getProductByBarcode(testBarcode);
      expect(product, isNotNull);
      
      final dto = product!.toDtoWithImageUrl();
      expect(dto.barcode, equals(testBarcode));
      expect(dto.name, equals('Workflow Test Product'));

      // UPDATE - Modifier via DTO
      final updatedDto = dto.copyWith(
        name: 'Updated Workflow Product',
        imageFileName: 'workflow_image.jpg',
      );
      
      final updateCompanion = updatedDto.toCompanion().copyWith(
        id: Value(product.id),  // ✅ ID interne pour l'update
      );
      await database.updateProduct(updateCompanion);

      // VERIFY - Vérifier par barcode
      final updatedProduct = await database.getProductByBarcode(testBarcode);
      expect(updatedProduct!.name, equals('Updated Workflow Product'));
      expect(updatedProduct.imageFileName, equals('workflow_image.jpg'));

      await database.close();
    });

    // ✅ NOUVEAU : Test de la conversion avec image URLs générées
    test('should generate correct image URLs by barcode', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const testBarcode = 6666666666;
      
      final companion = ProductsCompanion(
        barcode: const Value(testBarcode),
        name: const Value('Image URL Test'),
        imageFileName: const Value('test_image_file.jpg'),
      );

      await database.insertProduct(companion);
      final product = await database.getProductByBarcode(testBarcode);

      // Act
      final dtoWithImage = product!.toDtoWithImageUrl();
      final dtoWithoutImage = product.toDto();

      // Assert
      expect(dtoWithImage.barcode, equals(testBarcode));
      expect(dtoWithImage.imageUrl, equals('/api/images/compressed/test_image_file.jpg'));
      
      expect(dtoWithoutImage.barcode, equals(testBarcode));
      expect(dtoWithoutImage.imageUrl, isNull);  // ✅ Pas d'URL dans toDto()

      await database.close();
    });

    // ✅ NOUVEAU : Test de recherche multiple par barcodes
    test('should convert multiple products found by different barcodes', () async {
      // Arrange
      final database = DataDatabase.forTesting();
      const barcode1 = 7777777777;
      const barcode2 = 8888888888;
      
      // Créer plusieurs produits
      await database.insertProduct(ProductsCompanion(
        barcode: const Value(barcode1),
        name: const Value('Product 1'),
        imageFileName: const Value('image1.jpg'),
      ));
      
      await database.insertProduct(ProductsCompanion(
        barcode: const Value(barcode2),
        name: const Value('Product 2'),
        imageFileName: const Value('image2.jpg'),
      ));

      // Act - Récupérer et convertir par barcode
      final product1 = await database.getProductByBarcode(barcode1);
      final product2 = await database.getProductByBarcode(barcode2);
      
      final dto1 = product1!.toDtoWithImageUrl();
      final dto2 = product2!.toDtoWithImageUrl();

      // Assert
      expect(dto1.barcode, equals(barcode1));
      expect(dto1.name, equals('Product 1'));
      expect(dto1.imageUrl, equals('/api/images/compressed/image1.jpg'));
      
      expect(dto2.barcode, equals(barcode2));
      expect(dto2.name, equals('Product 2'));
      expect(dto2.imageUrl, equals('/api/images/compressed/image2.jpg'));

      await database.close();
    });
  });
}