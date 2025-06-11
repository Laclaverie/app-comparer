import 'dart:convert';
import 'package:data_server/services/image_service.dart' show ImageService;
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shared_models/productdto.dart';
import '../../lib/data_database.dart';
import '../../lib/services/product_service.dart';
import '../../lib/handlers/product_handlers.dart';

void main() {
  group('ProductHandlers', () {
    late DataDatabase database;
    late ImageService imageService;
    late ProductService service;
    late ProductHandlers handlers;

    setUp(() async {
      database = DataDatabase.forTesting();
      imageService = ImageService();  // ← Ajouté
      service = ProductService(database, imageService);  // ← Mis à jour
      handlers = ProductHandlers(service, imageService);  // ← Mis à jour si nécessaire
    });

    tearDown(() async {
      await database.close();
    });

    test('should get all products', () async {
      // Arrange
      await service.createProduct(ProductDto(
        barcode: 1111111111,
        name: 'Product 1',
      ));
      await service.createProduct(ProductDto(
        barcode: 2222222222,
        name: 'Product 2',
      ));

      final request = Request('GET', Uri.parse('http://localhost/api/products'));

      // Act
      final response = await handlers.getAllProducts(request);

      // Assert
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/json'));

      final body = await response.readAsString();
      final data = json.decode(body);
      expect(data['products'].length, equals(2));
      expect(data['count'], equals(2));
    });

    test('should get product by barcode', () async {
      // Arrange
      final created = await service.createProduct(ProductDto(
        barcode: 1234567890,
        name: 'Test Product',
      ));

      var request = Request(
        'GET',
        Uri.parse('http://localhost/api/products/barcode/1234567890'),
      );
      // Simuler les paramètres de route
      request = request.change(context: {'shelf_router/params': {'barcode': '1234567890'}});

      // Act
      final response = await handlers.getProductByBarcode(request);

      // Assert
      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      final product = ProductDto.fromJson(json.decode(body));
      expect(product.id, equals(created.id));
      expect(product.barcode, equals(1234567890));
    });

    test('should return 404 for non-existent barcode', () async {
      // Arrange
      var request = Request(
        'GET',
        Uri.parse('http://localhost/api/products/barcode/999999'),
      );
      request = request.change(context: {'shelf_router/params': {'barcode': '999999'}});

      // Act
      final response = await handlers.getProductByBarcode(request);

      // Assert
      expect(response.statusCode, equals(404));
    });

    test('should return 400 for invalid barcode format', () async {
      // Arrange
      var request = Request(
        'GET',
        Uri.parse('http://localhost/api/products/barcode/invalid'),
      );
      request = request.change(context: {'shelf_router/params': {'barcode': 'invalid'}});

      // Act
      final response = await handlers.getProductByBarcode(request);

      // Assert
      expect(response.statusCode, equals(400));
    });

    test('should create product', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'New Product',
        description: 'A new product',
      );

      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/products'),
        body: json.encode(dto.toJson()),
      );

      // Act
      final response = await handlers.createProduct(request);

      // Assert
      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      final created = ProductDto.fromJson(json.decode(body));
      expect(created.id, isNotNull);
      expect(created.barcode, equals(1234567890));
      expect(created.name, equals('New Product'));
    });

    test('should return 400 for invalid product data', () async {
      // Arrange
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/products'),
        body: 'invalid json', // Invalid JSON format
      );

      // Act
      final response = await handlers.createProduct(request);

      // Assert
      expect(response.statusCode, equals(400));
      
      final body = await response.readAsString();
      final error = json.decode(body);
      expect(error['error'], contains('Invalid JSON format'));
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

      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/products/search?q=Apple'),
      );

      // Act
      final response = await handlers.searchProducts(request);

      // Assert
      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      final data = json.decode(body);
      expect(data['products'].length, equals(1));
      expect(data['query'], equals('Apple'));
    });

    test('should return 400 for missing search query', () async {
      // Arrange
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/products/search'),
      );

      // Act
      final response = await handlers.searchProducts(request);

      // Assert
      expect(response.statusCode, equals(400));
    });

    test('should create product with image fields', () async {
      // Arrange
      final dto = ProductDto(
        barcode: 1234567890,
        name: 'New Product',
        description: 'A new product',
        imageFileName: 'test_image.jpg',  // ← Ajouté
      );

      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/products'),
        body: json.encode(dto.toJson()),
      );

      // Act
      final response = await handlers.createProduct(request);

      // Assert
      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      final created = ProductDto.fromJson(json.decode(body));
      expect(created.id, isNotNull);
      expect(created.imageFileName, equals('test_image.jpg'));
      expect(created.imageUrl, equals('/api/images/compressed/test_image.jpg'));  // ← URL générée
    });
  });
}