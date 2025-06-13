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
  
  Future<Map<String, dynamic>?> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
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