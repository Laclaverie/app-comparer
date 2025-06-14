import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:data_server/handlers/product_handlers.dart';
import 'package:data_server/handlers/image_handlers.dart';

class RouterWithLogging {
  final Router router = Router();
  final List<(String, String, String)> routes = [];
  
  // Helper pour ajouter route + log automatiquement
  void addRoute(String method, String path, Function handler, String description) {
    routes.add((method, path, description));
    switch (method.toUpperCase()) {
      case 'GET': router.get(path, handler); break;
      case 'POST': router.post(path, handler); break;
      case 'PUT': router.put(path, handler); break;
      case 'DELETE': router.delete(path, handler); break;
    }
  }
}

RouterWithLogging createRouterWithLogging(ProductHandlers productHandlers, ImageHandlers imageHandlers) {
  final routerWrapper = RouterWithLogging();
  
  // Core routes
  routerWrapper.addRoute('GET', '/', _rootHandler, 'API Info');
  routerWrapper.addRoute('GET', '/health', _healthHandler, 'Health Check');
  
  // Products routes
  routerWrapper.addRoute('GET', '/api/products', productHandlers.getAllProducts, 'List all products');
  routerWrapper.addRoute('GET', '/api/products/barcode/<barcode>', productHandlers.getProductByBarcode, 'Get product by barcode');
  routerWrapper.addRoute('GET', '/api/products/search', productHandlers.searchProducts, 'Search products');
  routerWrapper.addRoute('GET', '/api/products/<id>/prices', productHandlers.getProductPrices, 'Get product prices');
  routerWrapper.addRoute('POST', '/api/products', productHandlers.createProduct, 'Create product');
  routerWrapper.addRoute('PUT', '/api/products/<id>', productHandlers.updateProduct, 'Update product');
  routerWrapper.addRoute('DELETE', '/api/products/<id>', productHandlers.deleteProduct, 'Delete product');
  
  // Images routes
  routerWrapper.addRoute('POST', '/api/images/upload', imageHandlers.uploadImage, 'Upload image');
  routerWrapper.addRoute('GET', '/api/images/compressed/<filename>', imageHandlers.getCompressedImage, 'Get compressed image');
  routerWrapper.addRoute('GET', '/api/images/thumbnails/<filename>', imageHandlers.getThumbnail, 'Get thumbnail');
  
  // Admin routes
  routerWrapper.addRoute('POST', '/api/admin/test-products', productHandlers.addTestProduct, 'Add test product');

  return routerWrapper;
}

void printRoutes(List<(String, String, String)> routes, String ip, int port) {
  print('\n📋 Available endpoints (${routes.length} total):');
  
  // Grouper par catégorie
  final grouped = <String, List<(String, String, String)>>{};
  
  for (final (method, path, description) in routes) {
    final category = path.startsWith('/api/products') ? '📦 Products' :
                    path.startsWith('/api/images') ? '🖼️  Images' :
                    path.startsWith('/api/admin') ? '🔧 Admin' : '🏠 Core';
    grouped.putIfAbsent(category, () => []).add((method, path, description));
  }
  
  for (final category in grouped.keys) {
    print('\n   $category:');
    for (final (method, path, description) in grouped[category]!) {
      final fullUrl = 'http://$ip:$port$path';
      print('      ${method.padRight(6)} $path');
      print('               → $description');
      if (method == 'GET' && !path.contains('<')) {
        print('               🔗 $fullUrl');
      }
    }
  }
  
  print('\n📱 Base URL for your app: http://$ip:$port');
}

Response _rootHandler(Request req) => Response.ok('Data Server API v1.0');
Response _healthHandler(Request req) => Response.ok('{"status": "healthy"}');