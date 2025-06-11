import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/product_service.dart';
import 'package:shared_models/productdto.dart';

class ProductHandlers {
  final ProductService productService;

  ProductHandlers(this.productService);

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
      final data = json.decode(body) as Map<String, dynamic>;
      final productDto = ProductDto.fromJson(data);
      
      final created = await productService.createProduct(productDto);
      return Response.ok(
        json.encode(created.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on ArgumentError catch (e) {
      return Response.badRequest(
        body: json.encode({'error': e.message}),
      );
    } on StateError catch (e) {
      return Response(409, // Conflict
        body: json.encode({'error': e.message}),
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create product: $e'}),
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
}