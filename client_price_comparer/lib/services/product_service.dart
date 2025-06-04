import 'package:client_price_comparer/database/app_database.dart';
import 'package:flutter/foundation.dart';

enum ProductSearchResult {
  found,
  notFound,
  invalidBarcode,
}

class ProductSearchResponse {
  final ProductSearchResult result;
  final Product? product;
  final String? errorMessage;

  ProductSearchResponse({
    required this.result,
    this.product,
    this.errorMessage,
  });
}

class ProductService {
  final AppDatabase _db;

  ProductService(this._db);

  /// Search for a product by barcode in the local database
  Future<ProductSearchResponse> searchProductByBarcode(String barcode) async {
    try {
      // Convert string barcode to int
      final barcodeInt = int.parse(barcode);
      
      // Search for product in local database
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
    // TODO: Implement priority search queue logic
    // This could be a separate table in your database
    if (kDebugMode){
      print('Adding barcode $barcode to priority search queue');
    }
  }

  /// Start product registration flow
  Future<void> startProductRegistration(String barcode) async {
    // TODO: Implement product registration logic
    if (kDebugMode) {
    print('Starting product registration for barcode: $barcode');
    }
  }
}