import 'dart:io'; // ✅ AJOUT pour File

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

import '../database/app_database.dart';
import '../database/mappers/product_mapper.dart';

/// Résultat de la recherche de produit
enum ProductSearchResult {
  found,
  notFound,
  invalidBarcode,
}

/// Réponse de la recherche de produit
class ProductSearchResponse {
  final ProductSearchResult result;
  final ProductDto? productDto;
  final String? errorMessage;

  ProductSearchResponse({
    required this.result,
    this.productDto,
    this.errorMessage,
  });

  // ✅ Getter pour compatibilité avec l'ancien code
  @Deprecated('This getter will be removed in future versions. Use productDto instead.')
  ProductDto? get product => productDto;
}

class ProductService {
  final AppDatabase _database;

  ProductService(this._database);

  /// Rechercher un produit par code-barres
  Future<ProductSearchResponse> searchProductByBarcode(String barcode) async {
    try {
      // Validation du code-barres
      final barcodeInt = int.tryParse(barcode);
      if (barcodeInt == null || barcodeInt <= 0) {
        return ProductSearchResponse(
          result: ProductSearchResult.invalidBarcode,
          errorMessage: 'Invalid barcode format: $barcode',
        );
      }

      // Recherche en base locale d'abord
      final localProduct = await _database.getProductByBarcode(barcode);
      
      if (localProduct != null) {
        // ✅ Convertir Product Drift vers ProductDto
        final productDto = localProduct.toDto();
        
        // Marquer comme scanné
        await _database.markProductAsScanned(localProduct.id);
        
        return ProductSearchResponse(
          result: ProductSearchResult.found,
          productDto: productDto, // ✅ CORRECT
        );
      }

      // Si pas trouvé localement, chercher via API
      // TODO: Implémenter la recherche API
      
      return ProductSearchResponse(
        result: ProductSearchResult.notFound,
      );
      
    } catch (e) {
      return ProductSearchResponse(
        result: ProductSearchResult.invalidBarcode,
        errorMessage: 'Error searching product: $e',
      );
    }
  }

  /// Ajouter un produit depuis un DTO
  Future<int> addProductFromDto(ProductDto dto) async {
    final companion = dto.toInsertCompanion();
    return await _database.insertProduct(companion);
  }

  /// Récupérer un produit et le convertir en DTO
  Future<ProductDto?> getProductAsDto(int productId) async {
    final product = await _database.getProductById(productId);
    return product?.toDto();
  }

  /// Récupérer tous les produits en DTOs
  Future<List<ProductDto>> getAllProductsAsDtos() async {
    final products = await _database.getAllProducts();
    return products.map((p) => p.toDto()).toList();
  }

  /// Rechercher des produits
  Future<List<ProductDto>> searchProducts(String query) async {
    final products = await _database.searchProductsByName(query);
    return products.map((p) => p.toDto()).toList();
  }

  /// Ajouter à la queue de recherche prioritaire
  Future<void> addToPrioritySearchQueue(String barcode) async {
    // TODO: Implémenter la queue de recherche
    // Pour l'instant, juste log
    debugPrint('Added $barcode to priority search queue');
  }

  /// Naviguer vers l'enregistrement de produit
  Future<bool?> navigateToProductRegistration(BuildContext context, String barcode) async {
    // TODO: Implémenter la navigation vers l'enregistrement
    // Pour l'instant, retourner false
    debugPrint('Navigate to product registration for barcode: $barcode');
    return false;
  }

  // ===========================================
  // ✅ NOUVELLES MÉTHODES À AJOUTER
  // ===========================================

  /// Charger toutes les marques pour les dropdowns
  Future<List<Brand>> loadBrands() async {
    try {
      return await _database.getAllBrands();
    } catch (e) {
      debugPrint('Error loading brands: $e');
      return [];
    }
  }

  /// Charger toutes les catégories pour les dropdowns
  Future<List<Category>> loadCategories() async {
    try {
      return await _database.getAllCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  /// Sauvegarder un nouveau produit
  Future<void> saveProduct({
    required String barcode,
    required String name,
    int? brandId,
    int? categoryId,
    String? description,
    String? imageUrl,
  }) async {
    try {
      // Validation du code-barres
      final barcodeInt = int.tryParse(barcode);
      if (barcodeInt == null || barcodeInt <= 0) {
        throw Exception('Invalid barcode format: $barcode');
      }

      // Vérifier si le produit existe déjà
      final existing = await _database.getProductByBarcode(barcode);
      if (existing != null) {
        throw Exception('Product with barcode $barcode already exists');
      }

      // Créer le DTO
      final productDto = ProductDto(
        barcode: barcodeInt,
        name: name,
        description: description,
        brandId: brandId,
        categoryId: categoryId,
        imageUrl: imageUrl,
        localImagePath: imageUrl, // Si c'est un chemin local
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder via le mapper
      final productId = await _database.insertProduct(productDto.toInsertCompanion());
      
      debugPrint('Product saved with ID: $productId');
      
    } catch (e) {
      debugPrint('Error saving product: $e');
      rethrow;
    }
  }

  /// Navigation vers capture photo
  Future<String?> navigateToCameraCapture(BuildContext context, String barcode) async {
    try {
      // TODO: Implémenter la navigation vers la capture photo
      debugPrint('Navigate to camera capture for barcode: $barcode');
      
      // Simulation d'un délai de capture
      await Future.delayed(const Duration(seconds: 1));
      
      // Retourner un chemin fictif pour le test
      return '/storage/emulated/0/Pictures/${barcode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  // ===========================================
  // ✅ MÉTHODE MANQUANTE À AJOUTER
  // ===========================================

  /// Supprimer un produit et toutes ses données associées de manière robuste
  Future<bool> deleteProductWithImage(Product product) async {
    debugPrint('🗑️ Starting deletion of product: ${product.name} (ID: ${product.id})');
    
    bool hasErrors = false;
    final List<String> errorMessages = [];

    try {
      // ========================================
      // PHASE 1: Supprimer l'historique des prix
      // ========================================
      debugPrint('📊 Deleting price history for product ${product.id}...');
      try {
        final deletedPriceCount = await (_database.delete(_database.priceHistory)
          ..where((p) => p.productId.equals(product.id)))
          .go();
        
        debugPrint('✅ Deleted $deletedPriceCount price history entries');
      } catch (e) {
        hasErrors = true;
        final errorMsg = 'Failed to delete price history: $e';
        errorMessages.add(errorMsg);
        debugPrint('❌ $errorMsg');
      }

      // ========================================
      // PHASE 2: Supprimer les fichiers images
      // ========================================
      if (product.localImagePath != null && product.localImagePath!.isNotEmpty) {
        debugPrint('🖼️ Deleting local image: ${product.localImagePath}');
        try {
          await _deleteLocalImageFile(product.localImagePath!);
          debugPrint('✅ Local image deleted successfully');
        } catch (e) {
          hasErrors = true;
          final errorMsg = 'Failed to delete local image: $e';
          errorMessages.add(errorMsg);
          debugPrint('⚠️ $errorMsg');
          // Continue même si l'image ne peut pas être supprimée
        }
      }

      // ========================================
      // PHASE 3: Supprimer les alertes de prix (si applicable)
      // ========================================
      debugPrint('🔔 Cleaning up price alerts for product ${product.id}...');
      try {
        await _deleteProductPriceAlerts(product.id);
        debugPrint('✅ Price alerts cleaned up');
      } catch (e) {
        hasErrors = true;
        final errorMsg = 'Failed to delete price alerts: $e';
        errorMessages.add(errorMsg);
        debugPrint('⚠️ $errorMsg');
      }

      // ========================================
      // PHASE 4: Supprimer les références dans d'autres tables
      // ========================================
      debugPrint('🔗 Cleaning up related data...');
      try {
        await _cleanupProductReferences(product.id);
        debugPrint('✅ Related data cleaned up');
      } catch (e) {
        hasErrors = true;
        final errorMsg = 'Failed to cleanup references: $e';
        errorMessages.add(errorMsg);
        debugPrint('⚠️ $errorMsg');
      }

      // ========================================
      // PHASE 5: Supprimer le produit principal
      // ========================================
      debugPrint('🎯 Deleting main product record...');
      final productDeleted = await _database.deleteProduct(product.id);
      
      if (productDeleted) {
        debugPrint('✅ Product ${product.name} (ID: ${product.id}) deleted successfully');
        
        // Log du résumé
        if (hasErrors) {
          debugPrint('⚠️ Product deleted with ${errorMessages.length} warning(s):');
          for (final error in errorMessages) {
            debugPrint('   - $error');
          }
        }
        
        return true;
      } else {
        debugPrint('❌ Failed to delete main product record');
        return false;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Critical error during product deletion: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Supprimer le fichier image local de manière robuste
  Future<void> _deleteLocalImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // Vérifier que le fichier existe
      if (await file.exists()) {
        // Vérifier les permissions avant de supprimer
        final stat = await file.stat();
        if (stat.type == FileSystemEntityType.file) {
          await file.delete();
          debugPrint('🖼️ Successfully deleted image file: $imagePath');
        } else {
          throw Exception('Path is not a file: $imagePath');
        }
      } else {
        debugPrint('🖼️ Image file does not exist (already deleted?): $imagePath');
      }
      
    } catch (e) {
      // Re-throw pour que l'appelant puisse gérer l'erreur
      throw Exception('Error deleting image file "$imagePath": $e');
    }
  }

  /// Supprimer les alertes de prix pour un produit
  Future<void> _deleteProductPriceAlerts(int productId) async {
    try {
      // TODO: Implémenter quand vous aurez une table price_alerts
      // await (_database.delete(_database.priceAlerts)
      //   ..where((a) => a.productId.equals(productId)))
      //   .go();
      
      debugPrint('🔔 Price alerts cleanup completed (no alerts table yet)');
    } catch (e) {
      throw Exception('Error deleting price alerts: $e');
    }
  }

  /// Nettoyer les références dans d'autres tables
  Future<void> _cleanupProductReferences(int productId) async {
    try {
      // TODO: Ajouter d'autres nettoyages selon votre schéma :
      
      // 1. Supprimer les favoris (si vous avez une table favorites)
      // await (_database.delete(_database.favorites)
      //   ..where((f) => f.productId.equals(productId)))
      //   .go();
      
      // 2. Supprimer les notes/reviews (si vous avez une table reviews)
      // await (_database.delete(_database.reviews)
      //   ..where((r) => r.productId.equals(productId)))
      //   .go();
      
      // 3. Supprimer les entrées de shopping list (si applicable)
      // await (_database.delete(_database.shoppingListItems)
      //   ..where((s) => s.productId.equals(productId)))
      //   .go();
      
      debugPrint('🔗 Product references cleanup completed');
    } catch (e) {
      throw Exception('Error cleaning up product references: $e');
    }
  }

  /// Version simplifiée pour les DTOs
  Future<bool> deleteProductDto(ProductDto productDto) async {
    if (productDto.id == null) {
      debugPrint('❌ Cannot delete product: no ID provided in DTO');
      return false;
    }

    try {
      // Récupérer le Product Drift complet pour avoir toutes les infos
      final product = await _database.getProductById(productDto.id!);
      if (product == null) {
        debugPrint('❌ Product not found for deletion: ${productDto.id}');
        return false;
      }

      // Utiliser la méthode robuste complète
      return await deleteProductWithImage(product);
    } catch (e) {
      debugPrint('❌ Error deleting product DTO: $e');
      return false;
    }
  }

  /// Version simple pour suppression par ID seulement
  Future<bool> deleteProduct(int productId) async {
    try {
      final product = await _database.getProductById(productId);
      if (product == null) {
        debugPrint('❌ Product not found for deletion: $productId');
        return false;
      }

      return await deleteProductWithImage(product);
    } catch (e) {
      debugPrint('❌ Error deleting product by ID: $e');
      return false;
    }
  }

  /// Validation avant suppression (méthode utilitaire)
  Future<bool> canDeleteProduct(int productId) async {
    try {
      final product = await _database.getProductById(productId);
      if (product == null) return false;

      // Ajouter ici des règles métier si nécessaire :
      // - Vérifier si le produit n'est pas dans un panier actif
      // - Vérifier les permissions utilisateur
      // - etc.

      return true;
    } catch (e) {
      debugPrint('❌ Error checking if product can be deleted: $e');
      return false;
    }
  }

  /// Statistiques de suppression (pour les logs)
  Future<Map<String, int>> getProductDeletionStats(int productId) async {
    final stats = <String, int>{};
    
    try {
      // Compter les données associées avant suppression
      final priceHistoryCount = await (_database.select(_database.priceHistory)
        ..where((p) => p.productId.equals(productId)))
        .get();
      
      stats['priceHistoryEntries'] = priceHistoryCount.length;
      
      // TODO: Ajouter d'autres compteurs selon vos tables
      // final alertsCount = await (_database.select(_database.priceAlerts)
      //   ..where((a) => a.productId.equals(productId)))
      //   .get();
      // stats['priceAlerts'] = alertsCount.length;
      
      return stats;
    } catch (e) {
      debugPrint('❌ Error getting deletion stats: $e');
      return {};
    }
  }
}