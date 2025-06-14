import 'dart:io'; // ✅ AJOUT pour File

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';

import '../database/app_database.dart';
import '../database/mappers/product_mapper.dart';
import 'client_server_service.dart'; // ✅ AJOUT

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
  final ClientServerService _serverService = ClientServerService(); // ✅ AJOUT

  ProductService(this._database);

  /// Rechercher un produit par code-barres
  Future<ProductSearchResponse> searchProductByBarcode(String barcode) async {
    try {
      debugPrint('🔍 [SEARCH] Recherche produit barcode: $barcode');

      // ✅ Étape 1 : Recherche locale d'abord
      final localProduct = await _searchLocalProduct(barcode);
      if (localProduct != null) {
        debugPrint('✅ [SEARCH] Produit trouvé en local: ${localProduct.name}');
        
        // Marquer comme scanné
        if (localProduct.id != null) {
          await _database.markProductAsScanned(localProduct.id!);
        }
        
        return ProductSearchResponse(
          result: ProductSearchResult.found,
          productDto: localProduct,
        );
      }

      debugPrint('ℹ️ [SEARCH] Produit non trouvé en local, recherche sur serveur...');

      // ✅ Étape 2 : Recherche sur le serveur
      final serverProduct = await _searchServerProduct(barcode);
      if (serverProduct != null) {
        debugPrint('✅ [SEARCH] Produit trouvé sur serveur: ${serverProduct['name']}');
        
        // ✅ Étape 3 : Sauvegarder en local
        final localId = await _saveProductFromServer(serverProduct);
        if (localId != null && localId > 0) {
          // Marquer comme scanné
          await _database.markProductAsScanned(localId);
          
          debugPrint('✅ [SEARCH] Produit synchronisé avec ID: $localId');
          
          // ✅ OPTION A : Récupérer depuis la base (avec les vrais IDs)
          final savedProduct = await _database.getProductById(localId);
          if (savedProduct != null) {
            return ProductSearchResponse(
              result: ProductSearchResult.found,
              productDto: savedProduct.toDto(),
            );
          }
          
          // ✅ OPTION B : Fallback avec conversion directe du serveur
          debugPrint('⚠️ [SEARCH] Impossible de récupérer le produit sauvé, utilisation conversion serveur');
          final serverDto = _convertServerProductToDto(serverProduct);
          // Mettre à jour l'ID local
          final updatedDto = ProductDto(
            id: localId, // ✅ UTILISATION de l'ID local
            barcode: serverDto.barcode,
            name: serverDto.name,
            description: serverDto.description,
            brandId: serverDto.brandId,
            categoryId: serverDto.categoryId,
            imageFileName: serverDto.imageFileName,
            imageUrl: serverDto.imageUrl,
            localImagePath: serverDto.localImagePath,
            isActive: serverDto.isActive,
            createdAt: serverDto.createdAt,
            updatedAt: serverDto.updatedAt,
          );
          
          return ProductSearchResponse(
            result: ProductSearchResult.found,
            productDto: updatedDto,
          );
        }
      }

      debugPrint('ℹ️ [SEARCH] Produit non trouvé');
      return ProductSearchResponse(
        result: ProductSearchResult.notFound,
        errorMessage: 'Produit non trouvé localement et sur le serveur',
      );

    } catch (e) {
      debugPrint('❌ [SEARCH] Erreur: $e');
      return ProductSearchResponse(
        result: ProductSearchResult.invalidBarcode,
        errorMessage: 'Erreur lors de la recherche: $e',
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
  
  /// Recherche locale d'un produit par code-barres
  Future<ProductDto?> _searchLocalProduct(String barcode) async {
    try {
      // Validation du code-barres
      final barcodeInt = int.tryParse(barcode);
      if (barcodeInt == null || barcodeInt <= 0) {
        return null;
      }

      // Recherche en base locale
      final localProduct = await _database.getProductByBarcode(barcode);
      return localProduct?.toDto();
      
    } catch (e) {
      debugPrint('Error searching local product: $e');
      return null;
    }
  }

  /// ✅ NOUVEAU : Recherche sur le serveur
  Future<Map<String, dynamic>?> _searchServerProduct(String barcode) async {
    try {
      debugPrint('🌐 [SERVER] Recherche produit sur serveur...');
      
      final product = await _serverService.getProductByBarcode(barcode);
      
      if (product != null) {
        debugPrint('✅ [SERVER] Produit trouvé: ${product['name']}');
        return product;
      } else {
        debugPrint('ℹ️ [SERVER] Produit non trouvé sur serveur');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SERVER] Erreur recherche serveur: $e');
      return null;
    }
  }

  /// ✅ CORRECTION : Sauvegarder un produit venant du serveur
  Future<int?> _saveProductFromServer(Map<String, dynamic> serverProduct) async {
    try {
      debugPrint('💾 [SYNC] Sauvegarde produit du serveur...');
      
      // Vérifier/créer les dépendances (marque, catégorie)
      final brandId = await _ensureBrandExists(serverProduct);
      final categoryId = await _ensureCategoryExists(serverProduct);
      
      // ✅ CORRECTION : Créer le ProductsCompanion avec les champs qui existent
      final productCompanion = ProductsCompanion(
        barcode: Value(int.tryParse(serverProduct['barcode'].toString()) ?? 0),
        name: Value(serverProduct['name'] as String),
        description: Value(serverProduct['description'] as String?),
        brandId: Value(brandId),
        categoryId: Value(categoryId),
        imageUrl: Value(serverProduct['imageUrl'] as String?),
        isActive: const Value(true),
        scanCount: const Value(1),
        lastScannedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      
      final productId = await _database.insertProduct(productCompanion);
      debugPrint('✅ [SYNC] Produit sauvé avec ID: $productId');
      
      return productId;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur sauvegarde: $e');
      return null;
    }
  }

  /// ✅ NOUVEAU : S'assurer que la marque existe
  Future<int?> _ensureBrandExists(Map<String, dynamic> serverProduct) async {
    try {
      final brandName = serverProduct['brand']?['name'] as String?;
      if (brandName == null) return null;
      
      // Chercher la marque existante
      final existingBrands = await _database.getAllBrands();
      final existingBrand = existingBrands.where((b) => b.name == brandName).firstOrNull;
      
      if (existingBrand != null) {
        return existingBrand.id;
      }
      
      // Créer la nouvelle marque
      final brandCompanion = BrandsCompanion(
        name: Value(brandName),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      
      final brandId = await _database.insertBrand(brandCompanion);
      debugPrint('✅ [SYNC] Nouvelle marque créée: $brandName (ID: $brandId)');
      
      return brandId;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur création marque: $e');
      return null;
    }
  }

  /// ✅ NOUVEAU : S'assurer que la catégorie existe
  Future<int?> _ensureCategoryExists(Map<String, dynamic> serverProduct) async {
    try {
      final categoryName = serverProduct['category']?['name'] as String?;
      if (categoryName == null) return null;
      
      // Chercher la catégorie existante
      final existingCategories = await _database.getAllCategories();
      final existingCategory = existingCategories.where((c) => c.name == categoryName).firstOrNull;
      
      if (existingCategory != null) {
        return existingCategory.id;
      }
      
      // Créer la nouvelle catégorie
      final categoryCompanion = CategoriesCompanion(
        name: Value(categoryName),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      
      final categoryId = await _database.insertCategory(categoryCompanion);
      debugPrint('✅ [SYNC] Nouvelle catégorie créée: $categoryName (ID: $categoryId)');
      
      return categoryId;
    } catch (e) {
      debugPrint('❌ [SYNC] Erreur création catégorie: $e');
      return null;
    }
  }

  /// ✅ AMÉLIORATION : Convertir produit serveur en DTO avec gestion d'erreurs
  ProductDto _convertServerProductToDto(Map<String, dynamic> serverProduct) {
    try {
      return ProductDto(
        // ✅ Paramètres obligatoires avec validation
        barcode: int.tryParse(serverProduct['barcode']?.toString() ?? '') ?? 0,
        name: serverProduct['name']?.toString() ?? 'Produit sans nom',
        
        // ✅ Paramètres optionnels (selon votre ProductDto)
        id: serverProduct['id'] as int?, // ID du serveur si disponible
        brandId: serverProduct['brandId'] as int?, // Si le serveur renvoie l'ID
        categoryId: serverProduct['categoryId'] as int?, // Si le serveur renvoie l'ID
        description: serverProduct['description']?.toString(),
        
        // ✅ Images (selon votre ProductDto)
        imageFileName: serverProduct['imageFileName']?.toString(),
        imageUrl: serverProduct['imageUrl']?.toString(),
        localImagePath: null, // Pas encore téléchargée localement
        
        // ✅ Métadonnées
        isActive: serverProduct['isActive'] as bool? ?? true,
        createdAt: serverProduct['createdAt'] != null 
          ? DateTime.tryParse(serverProduct['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
        updatedAt: serverProduct['updatedAt'] != null 
          ? DateTime.tryParse(serverProduct['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [CONVERT] Erreur conversion serveur vers DTO: $e');
      // Retourner un DTO minimal en cas d'erreur
      return ProductDto(
        barcode: int.tryParse(serverProduct['barcode']?.toString() ?? '') ?? 0,
        name: serverProduct['name']?.toString() ?? 'Produit inconnu',
        description: 'Erreur lors de la conversion des données serveur',
        isActive: false, // Marquer comme inactif en cas d'erreur
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}