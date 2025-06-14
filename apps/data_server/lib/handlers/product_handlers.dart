import 'dart:convert';
import 'package:drift/drift.dart'; 
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/product_service.dart';
import 'package:data_server/services/image_service.dart';
import 'package:shared_models/productdto.dart';

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
        body: json.encode({'error': 'Failed to fetch products: $e'}),
      );
    }
  }

  Future<Response> getProductByBarcode(Request request) async {
    try {
      final barcode = request.params['barcode'];
      if (barcode == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Barcode parameter is required'}),
        );
      }

      final barcodeInt = int.tryParse(barcode);
      if (barcodeInt == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid barcode format'}),
        );
      }

      final product = await productService.getProductByBarcode(barcodeInt);
      if (product == null) {
        return Response.notFound(
          json.encode({'error': 'Product not found'}),
        );
      }

      return Response.ok(
        json.encode(product.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch product: $e'}),
      );
    }
  }

  Future<Response> createProduct(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;  // ← Peut lever FormatException
      final productDto = ProductDto.fromJson(data);  // ← Peut lever une exception aussi
    
      final created = await productService.createProduct(productDto);
      return Response.ok(
        json.encode(created.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on FormatException catch (e) {  // ← Ajoutez ce catch spécifique
      return Response.badRequest(
        body: json.encode({'error': 'Invalid JSON format: ${e.message}'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on TypeError catch (e) {  // ← Pour les erreurs de conversion de type
      return Response.badRequest(
        body: json.encode({'error': 'Invalid data format: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {  // ← Validation métier (nom vide, etc.)
      return Response.badRequest(
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } on StateError catch (e) {  // ← Conflit (barcode dupliqué)
      return Response(409, // Conflict
        body: json.encode({'error': e.message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {  // ← Toutes les autres erreurs → 500
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> searchProducts(Request request) async {
    try {
      final query = request.url.queryParameters['q'];
      if (query == null || query.trim().isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Search query parameter "q" is required'}),
        );
      }

      final products = await productService.searchProducts(query);
      return Response.ok(
        json.encode({
          'products': products.map((p) => p.toJson()).toList(),
          'count': products.length,
          'query': query,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to search products: $e'}),
      );
    }
  }

  Future<Response> updateProduct(Request request) async {
    try {
      final id = request.params['id'];
      if (id == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Product ID is required'}),
        );
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid product ID format'}),
        );
      }

      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final productDto = ProductDto.fromJson(data);
      
      // Assurer que l'ID correspond
      final updatedDto = productDto.copyWith(id: productId);
      final updated = await productService.updateProduct(updatedDto);
      
      return Response.ok(
        json.encode(updated.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update product: $e'}),
      );
    }
  }

  Future<Response> deleteProduct(Request request) async {
    try {
      final id = request.params['id'];
      if (id == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Product ID is required'}),
        );
      }

      final productId = int.tryParse(id);
      if (productId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid product ID format'}),
        );
      }

      await productService.deleteProduct(productId);
      return Response.ok(
        json.encode({'message': 'Product deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to delete product: $e'}),
      );
    }
  }

  Future<Response> uploadImage(Request request) async {
    try {
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.startsWith('multipart/form-data')) {
        return Response.badRequest(
          body: json.encode({'error': 'Content-Type must be multipart/form-data'}),
        );
      }

      // Note: Vous devrez implémenter le parsing multipart
      // ou utiliser une librairie comme 'mime' pour parser les uploads
      
      // Pour l'instant, exemple simplifié avec bytes directs
      final bytes = await request.read().expand((chunk) => chunk).toList();
      final imageBytes = Uint8List.fromList(bytes);
      
      final fileName = request.headers['x-filename'] ?? 'image.jpg';
      final compressedFileName = await imageService.saveAndCompressImage(
        imageBytes, 
        fileName,
      );

      return Response.ok(
        json.encode({
          'fileName': compressedFileName,
          'imageUrl': '/api/images/compressed/$compressedFileName',
          'thumbnailUrl': '/api/images/thumbnails/$compressedFileName',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to upload image: $e'}),
      );
    }
  }

  Future<Response> getCompressedImage(Request request) async {
    final fileName = request.params['filename'];
    if (fileName == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Filename is required'}),
      );
    }

    return imageService.getCompressedImage(fileName);
  }

  Future<Response> getThumbnail(Request request) async {
    final fileName = request.params['filename'];
    if (fileName == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Filename is required'}),
      );
    }

    return imageService.getThumbnail(fileName);
  }

  // ← Ajoutez cette méthode
  Future<Response> addTestProduct(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);

      final id = await productService.createProduct(
        ProductDto(
          barcode: data['barcode'],
          name: data['name'],
          description: data['description'],
        )
      );

      return Response.ok(
        json.encode({'success': true, 'id': id.id}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to add test product: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Récupérer les prix d'un produit par tous les magasins
  Future<Response> getProductPrices(Request request) async {
    final productIdStr = request.params['id'];
    final productId = int.tryParse(productIdStr ?? '');
    
    if (productId == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Invalid product ID'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      // Récupérer le paramètre 'since' pour filtrer par date
      final sinceParam = request.url.queryParameters['since'];
      DateTime? sinceDate;
      
      if (sinceParam != null) {
        try {
          sinceDate = DateTime.parse(sinceParam);
          print('📅 Filtering prices since: $sinceDate');
        } catch (e) {
          print('⚠️  Invalid since parameter: $sinceParam');
        }
      }

      // Construire la requête avec filtre optionnel par date
      var query = productService.database.select(productService.database.priceHistory).join([
        leftOuterJoin(productService.database.supermarkets, 
            productService.database.supermarkets.id.equalsExp(productService.database.priceHistory.supermarketId))
      ])..where(productService.database.priceHistory.productId.equals(productId));

      // Ajouter le filtre de date si spécifié
      if (sinceDate != null) {
        query = query..where(productService.database.priceHistory.date.isBiggerThanValue(sinceDate));
      }

      final results = await query.get();
      
      final prices = results.map((row) {
        final priceData = row.readTable(productService.database.priceHistory);
        final storeData = row.readTableOrNull(productService.database.supermarkets);
        
        return {
          'storeName': storeData?.name ?? 'Unknown Store',
          'price': priceData.price,
          'lastUpdated': priceData.date.toIso8601String(),
          'storeLocation': storeData?.location,
        };
      }).toList();

      print('🔍 Found ${prices.length} prices for product $productId' + 
            (sinceDate != null ? ' since $sinceDate' : ''));

      return Response.ok(
        json.encode(prices),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get product prices: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Récupérer l'historique des prix d'un produit (nouveau endpoint)
  Future<Response> getProductPriceHistory(Request request) async {
    final productIdStr = request.params['id'];
    final productId = int.tryParse(productIdStr ?? '');
    
    if (productId == null) {
      return Response.badRequest(
        body: json.encode({'error': 'Invalid product ID'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      // Paramètres optionnels
      final storeIdParam = request.url.queryParameters['storeId'];
      final daysParam = request.url.queryParameters['days'] ?? '30';
      final days = int.tryParse(daysParam) ?? 30;
      
      var query = productService.database.select(productService.database.priceHistory).join([
        leftOuterJoin(productService.database.supermarkets, 
            productService.database.supermarkets.id.equalsExp(productService.database.priceHistory.supermarketId))
      ])..where(productService.database.priceHistory.productId.equals(productId));

      // Filtrer par magasin si spécifié
      if (storeIdParam != null) {
        final storeId = int.tryParse(storeIdParam);
        if (storeId != null) {
          query = query..where(productService.database.priceHistory.supermarketId.equals(storeId));
        }
      }

      // Filtrer par période
      final sinceDate = DateTime.now().subtract(Duration(days: days));
      query = query..where(productService.database.priceHistory.date.isBiggerThanValue(sinceDate));

      // Ordonner par date
      query = query..orderBy([OrderingTerm.asc(productService.database.priceHistory.date)]);

      final results = await query.get();
      
      final history = results.map((row) {
        final priceData = row.readTable(productService.database.priceHistory);
        final storeData = row.readTableOrNull(productService.database.supermarkets);
        
        return {
          'date': priceData.date.toIso8601String(),
          'price': priceData.price,
          'storeName': storeData?.name ?? 'Unknown Store',
          'storeId': priceData.supermarketId,
          'isPromotion': priceData.isPromotion,
          'promotionDescription': priceData.promotionDescription,
        };
      }).toList();

      return Response.ok(
        json.encode(history),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get price history: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}