// apps/client/lib/database/data_migration_service.dart

import 'package:flutter/foundation.dart';
import 'app_database.dart';

class DataMigrationService {
  final AppDatabase _oldDb;
  final AppDatabase _newDb;
  
  DataMigrationService(this._oldDb, this._newDb);
  
  /// Export complet des données de l'ancienne base
  Future<Map<String, dynamic>> exportAllData() async {
    debugPrint('📤 [MIGRATION] Export des données existantes...');
    
    final exportData = <String, dynamic>{};
    
    try {
      // =======================================
      // EXPORT PRODUCTS (Version sécurisée)
      // =======================================
      debugPrint('📤 [EXPORT] Export des Products...');
      
      final rawProducts = await _oldDb.customSelect('''
        SELECT 
          id,
          barcode,
          name,
          description,
          brand_id,
          category_id,
          image_url,
          is_active,
          is_cached_locally,
          scan_count,
          last_scanned_at,
          last_synced_at
        FROM products
        WHERE id IS NOT NULL AND name IS NOT NULL
      ''').get();
      
      final products = rawProducts.map((row) => {
        'id': row.data['id'],
        'barcode': row.data['barcode'] ?? 0,
        'name': row.data['name'] ?? 'Produit inconnu',
        'description': row.data['description'] ?? '',
        'brand_id': row.data['brand_id'],
        'category_id': row.data['category_id'], 
        'image_url': row.data['image_url'],
        'is_active': (row.data['is_active'] ?? 1) == 1,
        'is_cached_locally': (row.data['is_cached_locally'] ?? 0) == 1,
        'scan_count': row.data['scan_count'] ?? 0,
        'last_scanned_at': row.data['last_scanned_at'],
        'last_synced_at': row.data['last_synced_at'],
      }).toList();
      
      exportData['products'] = products;
      debugPrint('✅ [EXPORT] ${products.length} produits exportés');
      
      // =======================================
      // EXPORT BRANDS
      // =======================================
      debugPrint('📤 [EXPORT] Export des Brands...');
      
      final rawBrands = await _oldDb.customSelect('''
        SELECT id, name, is_active
        FROM brands
        WHERE id IS NOT NULL AND name IS NOT NULL
      ''').get();
      
      final brands = rawBrands.map((row) => {
        'id': row.data['id'],
        'name': row.data['name'],
        'description': '',
        'is_active': (row.data['is_active'] ?? 1) == 1,
      }).toList();
      
      exportData['brands'] = brands;
      debugPrint('✅ [EXPORT] ${brands.length} marques exportées');
      
      // =======================================
      // EXPORT CATEGORIES
      // =======================================
      debugPrint('📤 [EXPORT] Export des Categories...');
      
      final rawCategories = await _oldDb.customSelect('''
        SELECT id, name, is_active
        FROM categories  
        WHERE id IS NOT NULL AND name IS NOT NULL
      ''').get();
      
      final categories = rawCategories.map((row) => {
        'id': row.data['id'],
        'name': row.data['name'],
        'description': '',
        'is_active': (row.data['is_active'] ?? 1) == 1,
      }).toList();
      
      exportData['categories'] = categories;
      debugPrint('✅ [EXPORT] ${categories.length} catégories exportées');
      
      // =======================================
      // EXPORT SUPERMARKETS
      // =======================================
      debugPrint('📤 [EXPORT] Export des Supermarkets...');
      
      final rawSupermarkets = await _oldDb.customSelect('''
        SELECT id, name, address, city, is_active
        FROM supermarkets
        WHERE id IS NOT NULL AND name IS NOT NULL
      ''').get();
      
      final supermarkets = rawSupermarkets.map((row) => {
        'id': row.data['id'],
        'name': row.data['name'],
        'address': row.data['address'] ?? '',
        'city': row.data['city'] ?? '',
        'is_active': (row.data['is_active'] ?? 1) == 1,
      }).toList();
      
      exportData['supermarkets'] = supermarkets;
      debugPrint('✅ [EXPORT] ${supermarkets.length} supermarchés exportés');
      
      // =======================================
      // EXPORT PRICE_HISTORY
      // =======================================
      debugPrint('📤 [EXPORT] Export du PriceHistory...');
      
      final rawPriceHistory = await _oldDb.customSelect('''
        SELECT 
          id, product_id, supermarket_id, price, date,
          is_promotion, promotion_description, original_price,
          source, is_validated
        FROM price_history
        WHERE id IS NOT NULL AND product_id IS NOT NULL
      ''').get();
      
      final priceHistory = rawPriceHistory.map((row) => {
        'id': row.data['id'],
        'product_id': row.data['product_id'],
        'supermarket_id': row.data['supermarket_id'],
        'price': row.data['price'],
        'date': row.data['date'],
        'is_promotion': (row.data['is_promotion'] ?? 0) == 1,
        'promotion_description': row.data['promotion_description'],
        'original_price': row.data['original_price'],
        'source': row.data['source'] ?? 'manual',
        'is_validated': (row.data['is_validated'] ?? 0) == 1,
      }).toList();
      
      exportData['price_history'] = priceHistory;
      debugPrint('✅ [EXPORT] ${priceHistory.length} entrées prix exportées');
      
      debugPrint('✅ [EXPORT] Export terminé avec succès');
      return exportData;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [EXPORT] Erreur durant l\'export: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Import avec SQL direct (plus flexible)
  Future<void> importAllData(Map<String, dynamic> data) async {
    debugPrint('📥 [IMPORT] Import des données dans la nouvelle base...');
    
    try {
      // =======================================
      // IMPORT BRANDS avec SQL direct
      // =======================================
      final brands = data['brands'] as List<dynamic>? ?? [];
      debugPrint('📥 [IMPORT] Import de ${brands.length} marques...');
      
      for (final brand in brands) {
        await _newDb.customStatement('''
          INSERT OR REPLACE INTO brands (id, name, is_active) 
          VALUES (?, ?, ?)
        ''', [
          brand['id'],
          brand['name'],
          brand['is_active'] ? 1 : 0,
        ]);
      }
      debugPrint('✅ [IMPORT] Marques importées');
      
      // =======================================
      // IMPORT CATEGORIES avec SQL direct
      // =======================================
      final categories = data['categories'] as List<dynamic>? ?? [];
      debugPrint('📥 [IMPORT] Import de ${categories.length} catégories...');
      
      for (final category in categories) {
        await _newDb.customStatement('''
          INSERT OR REPLACE INTO categories (id, name, is_active) 
          VALUES (?, ?, ?)
        ''', [
          category['id'],
          category['name'],
          category['is_active'] ? 1 : 0,
        ]);
      }
      debugPrint('✅ [IMPORT] Catégories importées');
      
      // =======================================
      // IMPORT PRODUCTS avec SQL direct
      // =======================================
      final products = data['products'] as List<dynamic>? ?? [];
      debugPrint('📥 [IMPORT] Import de ${products.length} produits...');
      
      for (final product in products) {
        await _newDb.customStatement('''
          INSERT OR REPLACE INTO products (
            id, barcode, name, description, brand_id, category_id, 
            image_url, is_active, is_cached_locally, scan_count
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          product['id'],
          product['barcode'],
          product['name'],
          product['description'],
          product['brand_id'],
          product['category_id'],
          product['image_url'],
          product['is_active'] ? 1 : 0,
          product['is_cached_locally'] ? 1 : 0,
          product['scan_count'],
        ]);
      }
      debugPrint('✅ [IMPORT] Produits importés');
      
      debugPrint('✅ [IMPORT] Import terminé avec succès');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [IMPORT] Erreur durant l\'import: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}