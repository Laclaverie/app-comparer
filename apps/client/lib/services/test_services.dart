// apps/client/lib/services/test_service.dart

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:shared_models/models/product/productdto.dart';
import '../database/app_database.dart';
import '../database/mappers/product_mapper.dart';

class TestService {
  static const bool _enableTests = kDebugMode; // ✅ Seulement en mode debug
  
  /// Lancer tous les tests de base de données
  static Future<void> runDatabaseTests() async {
    if (!_enableTests) return;
    
    debugPrint('🧪 [TEST] Début des tests de base de données...');
    
    final database = AppDatabase.forTesting();
    
    try {
      await _testProductOperations(database);
      await _testBrandOperations(database);
      await _testSupermarketOperations(database);
      await _testPriceHistoryOperations(database);
      
      debugPrint('🎉 [TEST] Tous les tests sont passés !');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [TEST] Erreur durant les tests: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    } finally {
      await database.close();
      debugPrint('🔧 [TEST] Base de données de test fermée');
    }
  }
  
  /// Test des opérations produits
  static Future<void> _testProductOperations(AppDatabase database) async {
    debugPrint('📝 [TEST] Test 1: Opérations produits...');
    
    // Test 1: Insertion d'un produit depuis DTO
    final testDto = ProductDto(
      barcode: 1234567890,
      name: 'Produit Test ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Description test',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final productId = await database.insertProduct(testDto.toInsertCompanion());
    debugPrint('✅ [TEST] Produit inséré avec ID: $productId');
    
    // Test 2: Récupération du produit
    final retrievedProduct = await database.getProductById(productId);
    if (retrievedProduct != null) {
      debugPrint('✅ [TEST] Produit récupéré: ${retrievedProduct.name}');
      
      // Test 3: Conversion vers DTO
      final dto = retrievedProduct.toDto();
      debugPrint('✅ [TEST] DTO créé: ${dto.name} (barcode: ${dto.barcode})');
      
      // Test 4: Mise à jour
      final updatedCompanion = dto.copyWith(
        name: '${dto.name} - Updated',
        updatedAt: DateTime.now(),
      ).toUpdateCompanion(
        existingId: productId,
      );
      
      final updateSuccess = await database.updateProduct(updatedCompanion);
      debugPrint('✅ [TEST] Produit mis à jour: $updateSuccess');
      
    } else {
      throw Exception('Produit non trouvé après insertion');
    }
  }
  
  /// Test des opérations marques
  static Future<void> _testBrandOperations(AppDatabase database) async {
    debugPrint('🏷️ [TEST] Test 2: Opérations marques...');
    
    final brandId = await database.insertBrand(BrandsCompanion.insert(
      name: 'Marque Test ${DateTime.now().millisecondsSinceEpoch}',
      logoUrl: const Value('https://example.com/logo.png'),
    ));
    debugPrint('✅ [TEST] Marque insérée avec ID: $brandId');
    
    final brands = await database.getAllBrands();
    debugPrint('✅ [TEST] ${brands.length} marque(s) trouvée(s)');
    
    if (brands.isNotEmpty) {
      final brand = brands.first;
      debugPrint('✅ [TEST] Première marque: ${brand.name}');
    }
  }
  
  /// Test des opérations supermarchés
  static Future<void> _testSupermarketOperations(AppDatabase database) async {
    debugPrint('🏪 [TEST] Test 3: Opérations supermarchés...');
    
    final supermarketId = await database.insertSupermarket(SupermarketsCompanion.insert(
      name: 'Supermarché Test ${DateTime.now().millisecondsSinceEpoch}',
      address: const Value('123 Rue de Test'),
      city: const Value('TestVille'),
    ));
    debugPrint('✅ [TEST] Supermarché inséré avec ID: $supermarketId');
    
    final supermarkets = await database.getAllSupermarkets();
    debugPrint('✅ [TEST] ${supermarkets.length} supermarché(s) trouvé(s)');
  }
  
  /// Test des opérations historique prix
  static Future<void> _testPriceHistoryOperations(AppDatabase database) async {
    debugPrint('💰 [TEST] Test 4: Opérations historique prix...');
    
    // D'abord créer un produit et un supermarché
    final productId = await database.insertProduct(ProductsCompanion.insert(
      barcode: 9876543210,
      name: 'Produit Prix Test',
    ));
    
    final supermarketId = await database.insertSupermarket(SupermarketsCompanion.insert(
      name: 'Super Prix Test',
    ));
    
    // Insérer un historique de prix
    final priceHistoryId = await database.insertPriceHistory(PriceHistoryCompanion.insert(
      productId: productId,
      supermarketId: supermarketId,
      price: 2.99,
      date: DateTime.now(),
    ));
    debugPrint('✅ [TEST] Historique prix inséré avec ID: $priceHistoryId');
    
    // Récupérer l'historique
    final priceHistory = await database.getPriceHistoryForProduct(productId);
    debugPrint('✅ [TEST] ${priceHistory.length} entrée(s) d\'historique trouvée(s)');
    
    if (priceHistory.isNotEmpty) {
      final entry = priceHistory.first;
      debugPrint('✅ [TEST] Premier prix: €${entry.price} le ${entry.date}');
    }
  }
  
  /// Test des statistiques de la base
  static Future<void> printDatabaseStats() async {
    if (!_enableTests) return;
    
    debugPrint('📊 [TEST] Statistiques de la base de données:');
    final database = AppDatabase();
    
    try {
      final products = await database.getAllProducts();
      final brands = await database.getAllBrands();
      final supermarkets = await database.getAllSupermarkets();
      
      debugPrint('   - Produits: ${products.length}');
      debugPrint('   - Marques: ${brands.length}');
      debugPrint('   - Supermarchés: ${supermarkets.length}');
      
    } catch (e) {
      debugPrint('❌ [TEST] Erreur stats: $e');
    } finally {
      await database.close();
    }
  }
  
  /// Nettoyer les données de test
  static Future<void> cleanupTestData() async {
    if (!_enableTests) return;
    
    debugPrint('🧹 [TEST] Nettoyage des données de test...');
    final database = AppDatabase();
    
    try {
      // Supprimer les produits de test (contenant "Test" dans le nom)
      final testProducts = await database.searchProductsByName('Test');
      for (final product in testProducts) {
        await database.deleteProduct(product.id);
      }
      
      debugPrint('✅ [TEST] ${testProducts.length} produit(s) de test supprimé(s)');
      
    } catch (e) {
      debugPrint('❌ [TEST] Erreur nettoyage: $e');
    } finally {
      await database.close();
    }
  }
}