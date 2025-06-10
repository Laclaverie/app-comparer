import 'package:client_price_comparer/database/app_database.dart' as db;
import 'package:client_price_comparer/services/file_system_service.dart' show FileSystemService;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:client_price_comparer/pages/product_registration_page.dart';
import 'package:client_price_comparer/pages/camera_capture_page.dart';

/// Defines the possible results when searching for a product by barcode
enum ProductSearchResult {
  found,
  notFound,
  invalidBarcode,
}

/// Response wrapper for product search operations
/// Contains the search result status, product data if found, and error information
class ProductSearchResponse {
  final ProductSearchResult result;
  final db.Product? product;
  final String? errorMessage;

  ProductSearchResponse({
    required this.result,
    this.product,
    this.errorMessage,
  });
}

/// Handles all product-related operations including search, registration, and management
/// Provides barcode lookup, navigation to product registration, and database operations
/// Integrates with camera capture and file system services for complete product workflow
class ProductService {
  final db.AppDatabase _db;

  ProductService(this._db);

  /// Search for a product by barcode in the local database
  Future<ProductSearchResponse> searchProductByBarcode(String barcode) async {
    try {
      final barcodeInt = int.parse(barcode);
      
      final product = await (_db.select(_db.products)
          ..where((tbl) => tbl.barcode.equals(barcodeInt)))
          .getSingleOrNull();

      if (product != null) {
        return ProductSearchResponse(
          result: ProductSearchResult.found,
          product: product,
        );
      } else {
        return ProductSearchResponse(
          result: ProductSearchResult.notFound,
        );
      }
    } catch (e) {
      return ProductSearchResponse(
        result: ProductSearchResult.invalidBarcode,
        errorMessage: 'Invalid barcode format: $barcode',
      );
    }
  }

  /// Add product to priority search queue (for offline search)
  Future<void> addToPrioritySearchQueue(String barcode) async {
    if (kDebugMode) {
      print('Added barcode $barcode to priority search queue');
    }
  }

  /// Navigate to product registration page
  Future<bool?> navigateToProductRegistration(BuildContext context, String barcode) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductRegistrationPage(
          appDatabase: _db,
          barcode: barcode,
        ),
      ),
    );
    return result;
  }

  /// Navigate to camera capture page
  Future<String?> navigateToCameraCapture(BuildContext context, String barcode) async {
    final String? imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCaptureePage(barcode: barcode),
      ),
    );
    return imagePath;
  }

  /// Load brands from database
  Future<List<db.Brand>> loadBrands() async {
    return await _db.select(_db.brands).get();
  }

  /// Load categories from database  
  Future<List<db.Category>> loadCategories() async {
    return await _db.select(_db.categories).get();
  }

  /// Save a new product to database
  Future<void> saveProduct({
    required String barcode,
    required String name,
    int? brandId,
    int? categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final barcodeInt = int.parse(barcode);
    
    final product = db.ProductsCompanion(
      barcode: Value(barcodeInt),
      name: Value(name.trim()),
      brandId: brandId != null ? Value(brandId) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      imageUrl: imageUrl != null && imageUrl.trim().isNotEmpty 
          ? Value(imageUrl.trim()) 
          : const Value.absent(),
      description: description != null && description.trim().isNotEmpty 
          ? Value(description.trim()) 
          : const Value.absent(),
    );
    
    await _db.into(_db.products).insert(product);
  }

  /// Delete a product and its associated image
  Future<bool> deleteProductWithImage(db.Product product) async {
    try {
      // Delete the product from database first
      await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(product.id))).go();
      
      // Delete the image using the stored path (much more reliable)
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        await FileSystemService.deleteProductImageByPath(product.imageUrl);
      }
      
      if (kDebugMode) {
        print('Deleted product ${product.name} (ID: ${product.id}) and associated image');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting product with image: $e');
      }
      return false;
    }
  }
}