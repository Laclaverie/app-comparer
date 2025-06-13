import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class ClientServerService {
  static const String baseUrl = 'http://192.168.18.5:8080';
  final Logger _logger = Logger('ClientServerService');
  
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Server health check failed: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products?limit=10'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map<String, dynamic> && data.containsKey('products')) {
          return List<Map<String, dynamic>>.from(data['products']);
        }
        // Si c'est directement une liste
        else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        
        return [];  // Liste vide par défaut
      }
      return null;
    } catch (e) {
      _logger.warning('Get products failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProductByBarcode(int barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/barcode/$barcode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      _logger.warning('Get product by barcode failed: $e');
      return null;
    }
  }
}