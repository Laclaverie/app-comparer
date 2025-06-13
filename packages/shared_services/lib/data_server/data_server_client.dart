import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_models/productdto.dart';

class DataServerClient {
  final String baseUrl;
  final String? apiKey;
  final Duration timeout;
  final int maxRetries;

  DataServerClient({
    required this.baseUrl,
    this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (apiKey != null) 'Authorization': 'Bearer $apiKey',
  };

  Future<T> _retry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts * 2));
        print('Retry attempt $attempts/$maxRetries after error: $e');
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<bool> ping() async {
    return await _retry(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(timeout);
      
      return response.statusCode == 200;
    });
  }

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? adminToken,
  }) async {
    return await _retry(() async {
      final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      
      final headers = Map<String, String>.from(_headers);
      if (adminToken != null) {
        headers['X-Admin-Token'] = adminToken;
      }
      
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw HttpException('Failed to get products: ${response.statusCode}');
    });
  }

  Future<ProductDto?> getProductByBarcode(int barcode) async {
    return await _retry(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/barcode/$barcode'),
        headers: _headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return ProductDto.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      throw HttpException('Failed to get product: ${response.statusCode}');
    });
  }

  Future<ProductDto> createProduct(ProductDto product) async {
    return await _retry(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: _headers,
        body: json.encode(product.toJson()),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return ProductDto.fromJson(json.decode(response.body));
      }
      throw HttpException('Failed to create product: ${response.statusCode}');
    });
  }

  Future<ProductDto> updateProduct(ProductDto product) async {
    if (product.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    return await _retry(() async {
      final response = await http.put(
        Uri.parse('$baseUrl/api/products/${product.id}'),
        headers: _headers,
        body: json.encode(product.toJson()),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return ProductDto.fromJson(json.decode(response.body));
      }
      throw HttpException('Failed to update product: ${response.statusCode}');
    });
  }

  Future<void> deleteProduct(int id) async {
    return await _retry(() async {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: _headers,
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw HttpException('Failed to delete product: ${response.statusCode}');
      }
    });
  }

  Future<List<ProductDto>> searchProducts(String query) async {
    return await _retry(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/search?q=${Uri.encodeComponent(query)}'),
        headers: _headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['products'] as List)
            .map((json) => ProductDto.fromJson(json))
            .toList();
      }
      throw HttpException('Failed to search products: ${response.statusCode}');
    });
  }

  Future<Map<String, dynamic>> getAllProductsAdmin(String adminToken) async {
    return await _retry(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/products/all'),
        headers: {
          ..._headers,
          'X-Admin-Token': adminToken,
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw HttpException('Admin access required');
      }
      throw HttpException('Failed to get all products: ${response.statusCode}');
    });
  }
}