import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'data_database.dart';
import 'services/product_service.dart';
import 'handlers/product_handlers.dart';

void main() async {
  // Initialiser la base de données
  final database = DataDatabase();
  final productService = ProductService(database);
  final productHandlers = ProductHandlers(productService);

  // Router avec paramètres
  final router = Router()
    ..get('/', _rootHandler)
    ..get('/health', _healthHandler)
    // Products routes
    ..get('/api/products', productHandlers.getAllProducts)
    ..get('/api/products/barcode/<barcode>', productHandlers.getProductByBarcode)
    ..get('/api/products/search', productHandlers.searchProducts)
    ..post('/api/products', productHandlers.createProduct)
    ..put('/api/products/<id>', productHandlers.updateProduct)
    ..delete('/api/products/<id>', productHandlers.deleteProduct);

  // Middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  // Serveur
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  
  print('🚀 Data Server running on http://${ip.address}:${server.port}');
  print('📋 Endpoints:');
  print('   GET    /api/products');
  print('   GET    /api/products/barcode/{barcode}');
  print('   GET    /api/products/search?q={query}');
  print('   POST   /api/products');
  print('   PUT    /api/products/{id}');
  print('   DELETE /api/products/{id}');
}

Response _rootHandler(Request req) => Response.ok('Data Server API v1.0');
Response _healthHandler(Request req) => Response.ok('{"status": "healthy"}');