import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_initialization.dart';
import 'config_service.dart';

class ClientServerService {
  final ConfigService? _configService; // nullable: use lazy fallback when needed
  final Logger _logger = Logger('ClientServerService');

  ClientServerService({ConfigService? configService}) : _configService = configService;

  String get _baseUrl {
    // Prefer injected config, otherwise try the app-level config, otherwise use a safe default
    if (_configService != null) return _configService.baseUrl;
    try {
      return AppInitializationService.configService.baseUrl;
    } catch (_) {
      // Fallback hardcoded to avoid throwing during early construction
      return 'http://localhost:8080';
    }
  }

  // Expose a testing-friendly getter so tests can assert the resolved value
  @visibleForTesting
  String get testableBaseUrl => _baseUrl;
  
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
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
        Uri.parse('$_baseUrl/api/products?limit=10'),
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

  /// ✅ NOUVEAU : Récupérer un produit par code-barres depuis le serveur
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      debugPrint('🌐 [SERVER] GET produit barcode: $barcode');
      debugPrint('   URL: $_baseUrl/api/products/barcode/$barcode');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/products/barcode/$barcode'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [SERVER] Réponse GET barcode:');
      debugPrint('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final productData = jsonDecode(response.body) as Map<String, dynamic>;
        
        debugPrint('✅ [SERVER] Produit récupéré:');
        debugPrint('   - ID: ${productData['id']}');
        debugPrint('   - Name: ${productData['name']}');
        debugPrint('   - Description: ${productData['description']}');
        debugPrint('   - Barcode: ${productData['barcode']}');
        
        return productData;
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ [SERVER] Produit non trouvé (404)');
        return null;
      } else {
        debugPrint('❌ [SERVER] Erreur GET: ${response.statusCode}');
        debugPrint('❌ [SERVER] Message: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Exception GET barcode: $e');
      return null;
    }
  }

  Future<bool> addProductToTestDB(Map<String, dynamic> productData) async {
    try {
      // ✅ AJOUT : Debug du payload côté service
      debugPrint('🌐 [SERVER] Envoi vers serveur:');
      debugPrint('   URL: $_baseUrl/api/products');
      debugPrint('   Method: POST');
      debugPrint('   Headers: Content-Type: application/json');
      debugPrint('   Body: ${jsonEncode(productData)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/products'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );

      // ✅ AJOUT : Debug de la réponse serveur
      debugPrint('📡 [SERVER] Réponse serveur:');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [SERVER] Produit ajouté avec succès');
        
        // ✅ BONUS : Parser la réponse pour voir ce qui a été créé
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('📋 [SERVER] Produit créé:');
          debugPrint('   - ID: ${responseData['id']}');
          debugPrint('   - Name: ${responseData['name']}');
          debugPrint('   - Description: ${responseData['description']}');
          debugPrint('   - Barcode: ${responseData['barcode']}');
        } catch (e) {
          debugPrint('⚠️ [SERVER] Impossible de parser la réponse: $e');
        }
        
        return true;
      } else {
        debugPrint('❌ [SERVER] Erreur serveur: ${response.statusCode}');
        debugPrint('❌ [SERVER] Message: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Exception lors de l\'ajout: $e');
      return false;
    }
  }

  /// ✅ AJOUT : Mettre à jour un produit existant
  Future<bool> updateProductInTestDB(Map<String, dynamic> productData) async {
    try {
      final barcode = productData['barcode'];
      
      // ✅ Étape 1 : Récupérer l'ID du produit via son barcode
      debugPrint('🔍 [UPDATE] Recherche de l\'ID du produit...');
      final existingProduct = await getProductByBarcode(barcode);
      
      if (existingProduct == null) {
        debugPrint('❌ [UPDATE] Produit non trouvé pour barcode: $barcode');
        return false;
      }
      
      final productId = existingProduct['id'];
      debugPrint('✅ [UPDATE] Produit trouvé avec ID: $productId');
      
      // ✅ Étape 2 : Mettre à jour via l'ID
      debugPrint('🔄 [SERVER] Mise à jour produit:');
      debugPrint('   URL: $_baseUrl/api/products/$productId');
      debugPrint('   Method: PUT');
      debugPrint('   Headers: Content-Type: application/json');
      debugPrint('   Body: ${jsonEncode(productData)}');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );

      debugPrint('📡 [SERVER] Réponse mise à jour:');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [SERVER] Produit mis à jour avec succès');
        
        // ✅ Parser la réponse
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('📋 [SERVER] Produit mis à jour:');
          debugPrint('   - ID: ${responseData['id']}');
          debugPrint('   - Name: ${responseData['name']}');
          debugPrint('   - Description: ${responseData['description']}');
          debugPrint('   - Barcode: ${responseData['barcode']}');
        } catch (e) {
          debugPrint('⚠️ [SERVER] Impossible de parser la réponse: $e');
        }
        
        return true;
      } else {
        debugPrint('❌ [SERVER] Erreur mise à jour: ${response.statusCode}');
        debugPrint('❌ [SERVER] Message: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Exception mise à jour: $e');
      return false;
    }
  }

  /// ✅ BONUS : Vérifier si un produit existe
  Future<bool> checkProductExists(String barcode) async {
    try {
      debugPrint('🔍 [SERVER] Vérification existence produit:');
      debugPrint('   URL: $_baseUrl/api/products/barcode/$barcode');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/products/barcode/$barcode'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [SERVER] Réponse vérification:');
      debugPrint('   Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ [SERVER] Produit existe');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ [SERVER] Produit n\'existe pas');
        return false;
      } else {
        debugPrint('⚠️ [SERVER] Erreur vérification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Exception vérification: $e');
      return false;
    }
  }

  /// ✅ BONUS : Supprimer un produit
  Future<bool> deleteProductFromTestDB(String barcode) async {
    try {
      debugPrint('🗑️ [SERVER] Suppression produit:');
      debugPrint('   URL: $_baseUrl/api/products/barcode/$barcode');
      debugPrint('   Method: DELETE');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/products/barcode/$barcode'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [SERVER] Réponse suppression:');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [SERVER] Produit supprimé avec succès');
        return true;
      } else {
        debugPrint('❌ [SERVER] Erreur suppression: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Exception suppression: $e');
      return false;
    }
  }

  Future<Map<String, String>> addOrUpdateProductToTestDB(Map<String, dynamic> productData) async {
    try {
      // Essayer d'abord d'ajouter
      final addResponse = await addProductToTestDB(productData);
      
      if (addResponse) {
        return {'success': 'true', 'action': 'created', 'message': 'Produit créé avec succès'};
      }
      
      // Si échec, essayer de mettre à jour
      final updateResponse = await updateProductInTestDB(productData);
      if (updateResponse) {
        return {'success': 'true', 'action': 'updated', 'message': 'Produit mis à jour avec succès'};
      }
      
      return {'success': 'false', 'action': 'failed', 'message': 'Échec de l\'opération'};
      
    } catch (e) {
      return {'success': 'false', 'action': 'error', 'message': 'Erreur: $e'};
    }
  }
}