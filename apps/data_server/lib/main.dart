import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'data_database.dart';
import 'services/product_service.dart';
import 'services/image_service.dart';
import 'handlers/product_handlers.dart';
import 'handlers/image_handlers.dart';

void main() async {
  // Initialiser les services
  final database = DataDatabase.development();
  final imageService = ImageService();
  final productService = ProductService(database, imageService);
  
  // Initialiser les handlers
  final productHandlers = ProductHandlers(productService,imageService);
  final imageHandlers = ImageHandlers(imageService);

  // Router avec gestion des images
  final router = Router()
    ..get('/', _rootHandler)
    ..get('/health', _healthHandler)
    
    // Products routes
    ..get('/api/products', productHandlers.getAllProducts)
    ..get('/api/products/barcode/<barcode>', productHandlers.getProductByBarcode)
    ..get('/api/products/search', productHandlers.searchProducts)
    ..get('/api/products/<id>/prices', productHandlers.getProductPrices)
    ..post('/api/products', productHandlers.createProduct)
    ..put('/api/products/<id>', productHandlers.updateProduct)
    ..delete('/api/products/<id>', productHandlers.deleteProduct)
    
    // Images routes
    ..post('/api/images/upload', imageHandlers.uploadImage)
    ..get('/api/images/compressed/<filename>', imageHandlers.getCompressedImage)
    ..get('/api/images/thumbnails/<filename>', imageHandlers.getThumbnail)
    
    // Route pour ajouter des produits de test
    ..post('/api/admin/test-products', productHandlers.addTestProduct);

  // Middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
      
  // Récupérer la vraie IP de la machine
  final interfaces = await NetworkInterface.list();
  final wifiInterface = interfaces
      .where((interface) => interface.name.contains('Wi-Fi') || interface.name.contains('wlan'))
      .expand((interface) => interface.addresses)
      .where((address) => address.type == InternetAddressType.IPv4)
      .firstOrNull;
  // Serveur
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  
  print('🚀 Data Server running on:');
  print('   Local:    http://localhost:${server.port}');
  if (wifiInterface != null) {
    print('   Network:  http://${wifiInterface.address}:${server.port}');
  }
  print('   All IPs:  http://0.0.0.0:${server.port}');
  print('📋 Endpoints:');
  print('   GET    /api/products');
  print('   POST   /api/images/upload');
  print('   GET    /api/images/compressed/{filename}');
  print('   GET    /api/images/thumbnails/{filename}');
}

Response _rootHandler(Request req) => Response.ok('Data Server API v1.0');
Response _healthHandler(Request req) => Response.ok('{"status": "healthy"}');