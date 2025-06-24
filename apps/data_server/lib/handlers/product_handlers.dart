import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/product_service.dart';
import '../services/image_service.dart';

class ProductHandlers {
  final ProductService productService;
  final ImageService imageService;
  
  ProductHandlers(this.productService, this.imageService);

  Future<Response> getAllProducts(Request request) async {
    try {
      final products = await productService.getAllProducts();
      
      return Response.ok(
        json.encode({
          'products': products.map((p) => p.toJson()).toList(),
          'count': products.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get products: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getProductByBarcode(Request request) async {
    try {
      final barcodeParam = request.params['barcode'];
      final barcode = int.tryParse(barcodeParam ?? '');
      
      if (barcode == null || barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final product = await productService.getProductByBarcode(barcode);
      
      if (product == null) {
        return Response.notFound(
          json.encode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        json.encode(product.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> createProduct(Request request) async {
    try {
      final body = await request.readAsString();
      
      Map<String, dynamic> data;
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid JSON format'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final productDto = ProductDto.fromJson(data);
      final created = await productService.createProduct(productDto);
      
      return Response.ok(
        json.encode(created.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: json.encode({'error': 'Failed to create product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ✅ NOUVELLES MÉTHODES : Recherche par marque(s)
  Future<Response> searchProductsByBrand(Request request) async {
    try {
      final brandName = request.url.queryParameters['brand'];
      final limitParam = request.url.queryParameters['limit'];
      
      if (brandName == null || brandName.trim().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Brand name parameter "brand" is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validation
      final sanitizedBrand = brandName.trim();
      if (sanitizedBrand.length > 50) {
        return Response.badRequest(
          body: json.encode({'error': 'Brand name too long (max 50 characters)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      int? limit;
      if (limitParam != null) {
        limit = int.tryParse(limitParam);
        if (limit == null || limit <= 0 || limit > 100) {
          return Response.badRequest(
            body: json.encode({'error': 'Invalid limit (must be 1-100)'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      // Service call
      final products = await productService.searchProductsByBrand(sanitizedBrand, limit: limit);
      
      return Response.ok(
        json.encode({
          'products': products.map((p) => p.toJson()).toList(),
          'count': products.length,
          'brand': sanitizedBrand,
          'limited': limit != null && products.length == limit,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Brand search error: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Brand search temporarily unavailable'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> searchProductsByBrands(Request request) async {
    try {
      final brandsParam = request.url.queryParameters['brands'];
      final limitParam = request.url.queryParameters['limit'];
      
      if (brandsParam == null || brandsParam.trim().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Brands parameter "brands" is required (comma-separated)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse des marques (séparées par virgules)
      final brandNames = brandsParam
          .split(',')
          .map((brand) => brand.trim())
          .where((brand) => brand.isNotEmpty)
          .toList();

      if (brandNames.isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'No valid brand names provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (brandNames.length > 10) {
        return Response.badRequest(
          body: json.encode({'error': 'Too many brands (max 10)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      int? limit;
      if (limitParam != null) {
        limit = int.tryParse(limitParam);
        if (limit == null || limit <= 0 || limit > 200) {
          return Response.badRequest(
            body: json.encode({'error': 'Invalid limit (must be 1-200)'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      // Service call
      final products = await productService.searchProductsByBrands(brandNames, limit: limit);
      
      return Response.ok(
        json.encode({
          'products': products.map((p) => p.toJson()).toList(),
          'count': products.length,
          'brands': brandNames,
          'brandsCount': brandNames.length,
          'limited': limit != null && products.length == limit,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Multi-brands search error: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Multi-brands search temporarily unavailable'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> searchProductsByBrandId(Request request) async {
    try {
      final brandIdParam = request.params['brandId'];
      final brandId = int.tryParse(brandIdParam ?? '');
      
      if (brandId == null || brandId <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid brand ID required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limitParam = request.url.queryParameters['limit'];
      int? limit;
      if (limitParam != null) {
        limit = int.tryParse(limitParam);
        if (limit == null || limit <= 0 || limit > 100) {
          limit = 50; // Limite par défaut
        }
      }

      final products = await productService.searchProductsByBrandId(brandId, limit: limit);
      
      return Response.ok(
        json.encode({
          'products': products.map((p) => p.toJson()).toList(),
          'count': products.length,
          'brandId': brandId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to search products by brand ID: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> updateProduct(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final productDto = ProductDto.fromJson(data);
      
      if (productDto.barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required in product data'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final updated = await productService.updateProduct(productDto);
      
      return Response.ok(
        json.encode(updated.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> deleteProductByBarcode(Request request) async {
    try {
      final barcodeParam = request.params['barcode'];
      final barcode = int.tryParse(barcodeParam ?? '');
      
      if (barcode == null || barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await productService.deleteProductByBarcode(barcode);
      
      return Response.ok(
        json.encode({'message': 'Product deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to delete product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ✅ BONUS : Méthodes pour les marques
  Future<Response> getAllBrands(Request request) async {
    try {
      final brands = await productService.getAllBrands();
      
      return Response.ok(
        json.encode({
          'brands': brands.map((b) => b.toJson()).toList(),
          'count': brands.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get brands: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> searchBrands(Request request) async {
    try {
      final query = request.url.queryParameters['q'];
      if (query == null || query.trim().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Search query parameter "q" is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final brands = await productService.searchBrands(query);
      
      return Response.ok(
        json.encode({
          'brands': brands.map((b) => b.toJson()).toList(),
          'count': brands.length,
          'query': query,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to search brands: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> updateProductByBarcode(Request request) async {
    try {
      final barcodeParam = request.params['barcode'];
      final barcode = int.tryParse(barcodeParam ?? '');
      
      if (barcode == null || barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      Map<String, dynamic> data;
      
      try {
        data = json.decode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid JSON format'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // S'assurer que le barcode correspond
      data['barcode'] = barcode;
      
      final productDto = ProductDto.fromJson(data);
      final updated = await productService.updateProduct(productDto);
      
      return Response.ok(
        json.encode(updated.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getCurrentPricesByBarcode(Request request) async {
    try {
      final barcodeParam = request.params['barcode'];
      final barcode = int.tryParse(barcodeParam ?? '');
      
      if (barcode == null || barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Filtres optionnels
      final storeNamesParam = request.url.queryParameters['stores'];
      List<String>? storeFilter;
      if (storeNamesParam != null && storeNamesParam.trim().isNotEmpty) {
        storeFilter = storeNamesParam
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      final prices = await productService.getCurrentPricesByBarcode(
        barcode,
        storeFilter: storeFilter,
      );

      print('Current prices for barcode $barcode: ${prices.length} found');

      return Response.ok(
        json.encode({
          'prices': prices.map((p) => p.toJson()).toList(),
          'count': prices.length,
          'barcode': barcode,
          'storeFilter': storeFilter,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get current prices: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getPriceHistoryByBarcode(Request request) async {
    try {
      final barcodeParam = request.params['barcode'];
      final barcode = int.tryParse(barcodeParam ?? '');
      
      if (barcode == null || barcode <= 0) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid barcode required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Paramètres optionnels
      final storeFilter = request.url.queryParameters['store'];
      final sinceParam = request.url.queryParameters['since'];
      final limitDaysParam = request.url.queryParameters['limitDays'];
      final storeNamesParam = request.url.queryParameters['stores'];

      DateTime? since;
      if (sinceParam != null) {
        since = DateTime.tryParse(sinceParam);
        if (since == null) {
          return Response.badRequest(
            body: json.encode({'error': 'Invalid date format for "since" parameter (use ISO 8601)'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      int limitDays = 30; // Défaut
      if (limitDaysParam != null) {
        final parsedLimit = int.tryParse(limitDaysParam);
        if (parsedLimit == null || parsedLimit <= 0 || parsedLimit > 365) {
          return Response.badRequest(
            body: json.encode({'error': 'Invalid limitDays (must be 1-365)'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        limitDays = parsedLimit;
      }

      List<String>? storeNames;
      if (storeNamesParam != null && storeNamesParam.trim().isNotEmpty) {
        storeNames = storeNamesParam
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      final history = await productService.getPriceHistoryByBarcode(
        barcode,
        storeFilter: storeFilter,
        since: since,
        limitDays: limitDays,
        storeNames: storeNames,
      );
      
      return Response.ok(
        json.encode({
          'history': history.map((p) => p.toJson()).toList(),
          'count': history.length,
          'barcode': barcode,
          'filters': {
            'store': storeFilter,
            'since': since?.toIso8601String(),
            'limitDays': limitDays,
            'storeNames': storeNames,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get price history: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> addTestProduct(Request request) async {
    try {
      // Génération d'un produit de test avec barcode aléatoire
      final random = DateTime.now().millisecondsSinceEpoch;
      final testBarcode = 1000000000 + (random % 999999999); // 10 chiffres
      
      final testProduct = ProductDto(
        barcode: testBarcode,
        name: 'Test Product ${random.toString().substring(8)}',
        description: 'Generated test product for API testing',
        imageFileName: null,
      );

      final created = await productService.createProduct(testProduct);
      
      return Response.ok(
        json.encode({
          'message': 'Test product created successfully',
          'product': created.toJson(),
          'testInfo': {
            'generatedAt': DateTime.now().toIso8601String(),
            'barcode': testBarcode,
            'testUrls': {
              'get': '/api/products/barcode/$testBarcode',
              'update': '/api/products/barcode/$testBarcode',
              'delete': '/api/products/barcode/$testBarcode',
              'prices': '/api/products/barcode/$testBarcode/current-prices',
              'history': '/api/products/barcode/$testBarcode/price-history',
            },
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create test product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}