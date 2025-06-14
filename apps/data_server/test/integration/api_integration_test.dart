import 'dart:convert';
import 'dart:io';
import 'package:data_server/services/image_service.dart';
import 'package:test/test.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/models/product/productdto.dart';
import '../../lib/data_database.dart';
import '../../lib/services/product_service.dart';
import '../../lib/handlers/product_handlers.dart';

void main() {
  group('API Integration Tests', () {
    late HttpServer server;
    late DataDatabase database;
    late String baseUrl;
    late ImageService imageService;

    setUp(() async {
      // Setup database
      database = DataDatabase.forTesting();
      imageService = ImageService();
      final productService = ProductService(database,imageService);
      final productHandlers = ProductHandlers(productService,imageService);

      // Setup router
      final router = Router()
        ..get('/api/products', productHandlers.getAllProducts)
        ..get('/api/products/barcode/<barcode>', productHandlers.getProductByBarcode)
        ..post('/api/products', productHandlers.createProduct)
        ..get('/api/products/search', productHandlers.searchProducts);

      // Start server
      server = await serve(router, InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      await server.close();
      await database.close();
    });

    test('should create and retrieve product via HTTP', () async {
      // Arrange
      final newProduct = ProductDto(
        barcode: 1234567890,
        name: 'Integration Test Product',
        description: 'Created via HTTP',
      );

      // Act - Create product
      final createResponse = await HttpClient().postUrl(Uri.parse('$baseUrl/api/products'))
        ..headers.contentType = ContentType.json
        ..write(json.encode(newProduct.toJson()));
      final createResult = await createResponse.close();
      final createBody = await createResult.transform(utf8.decoder).join();
      final createdProduct = ProductDto.fromJson(json.decode(createBody));

      // Act - Get all products
      final getResponse = await HttpClient().getUrl(Uri.parse('$baseUrl/api/products'));
      final getResult = await getResponse.close();
      final getBody = await getResult.transform(utf8.decoder).join();
      final allProducts = json.decode(getBody);

      // Assert
      expect(createResult.statusCode, equals(200));
      expect(createdProduct.id, isNotNull);
      expect(createdProduct.name, equals('Integration Test Product'));

      expect(getResult.statusCode, equals(200));
      expect(allProducts['products'].length, equals(1));
      expect(allProducts['count'], equals(1));
    });

    test('should search products via HTTP', () async {
      // Arrange - Create test products
      await _createProductViaHttp(baseUrl, ProductDto(
        barcode: 1111111111,
        name: 'Apple iPhone',
      ));
      await _createProductViaHttp(baseUrl, ProductDto(
        barcode: 2222222222,
        name: 'Samsung Galaxy',
      ));

      // Act
      final response = await HttpClient().getUrl(
        Uri.parse('$baseUrl/api/products/search?q=Apple'),
      );
      final result = await response.close();
      final body = await result.transform(utf8.decoder).join();
      final searchResults = json.decode(body);

      // Assert
      expect(result.statusCode, equals(200));
      expect(searchResults['products'].length, equals(1));
      expect(searchResults['products'][0]['name'], contains('Apple'));
    });
  });
}

Future<ProductDto> _createProductViaHttp(String baseUrl, ProductDto product) async {
  final request = await HttpClient().postUrl(Uri.parse('$baseUrl/api/products'))
    ..headers.contentType = ContentType.json
    ..write(json.encode(product.toJson()));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return ProductDto.fromJson(json.decode(body));
}