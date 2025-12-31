// apps/client/lib/services/app_initialization.dart

import 'package:flutter/foundation.dart';
import 'test_services.dart';
import 'config_service.dart';
import '../database/app_database.dart';
import '../database/data_migration_service.dart';



class AppInitializationService {
  static bool _isInitialized = false;
  static AppDatabase? _database;
  static ConfigService? _configService;

  /// Getter pour accéder à la base depuis l'extérieur
  static AppDatabase get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Getter pour accéder à la configuration depuis l'extérieur
  static ConfigService get configService {
    // Ensure we always return a usable ConfigService even if initialization hasn't run yet.
    // This performs a lazy initialization and starts asynchronous init in background.
    if (_configService == null) {
      _configService = ConfigService();
      // Start init asynchronously; don't await here to keep this getter sync-safe.
      _configService!.init().then((_) {
        debugPrint('✅ [INIT] Lazy ConfigService initialization completed');
      }).catchError((e) {
        debugPrint('⚠️ [INIT] Lazy ConfigService initialization failed: $e');
      });
    }
    return _configService!;
  }
  
  /// Initialiser l'application
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🚀 [INIT] Initialisation de l\'application...');
    
    try {
      // 1. Initialiser la base de données
      await _initializeDatabase();
      
      // 2. Lancer les tests en mode debug
      if (kDebugMode) {
        await TestService.runDatabaseTests();
        await TestService.printDatabaseStats();
      }
      
      // 3. Autres initialisations...
      await _initializeServices();
      
      _isInitialized = true;
      debugPrint('✅ [INIT] Application initialisée avec succès');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [INIT] Erreur d\'initialisation: $e');
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
  
  /// Initialiser la base de données
  static Future<void> _initializeDatabase() async {
    debugPrint('💾 [INIT] Initialisation de la base de données...');
    
    try {
      // ✅ NOUVEAU : Vérifier si migration nécessaire AVANT d'ouvrir la nouvelle base
      await _migrateFromOldDatabaseIfNeeded();
      
      // ✅ CORRECTION : Assigner à la variable statique
      _database = AppDatabase();
      
      // Tester la nouvelle base
      final products = await _database!.getAllProducts();
      debugPrint('✅ [INIT] Base de données opérationnelle - ${products.length} produit(s)');
      
    } catch (e) {
      debugPrint('❌ [INIT] Erreur d\'initialisation: $e');
      rethrow;
    }
  }
  
  /// Migrer depuis l'ancienne base si elle existe
  static Future<void> _migrateFromOldDatabaseIfNeeded() async {
    AppDatabase? oldDb;
    
    try {
      debugPrint('🔍 [MIGRATION] Vérification d\'une ancienne base...');
      
      // ✅ CORRECTION : Utiliser le bon nom de méthode (sans underscore)
      oldDb = AppDatabase.createOldDb();
      
      // Vérifier si elle contient des données
      final oldProducts = await oldDb.customSelect('SELECT COUNT(*) as count FROM products').getSingle();
      final oldCount = oldProducts.data['count'] as int;
      
      if (oldCount > 0) {
        debugPrint('🔄 [MIGRATION] Ancienne base détectée avec $oldCount produits');
        debugPrint('🔄 [MIGRATION] Lancement de la migration vers base propre...');
        
        // ✅ CORRECTION : Utiliser le bon nom de méthode (sans underscore)
        final newDb = AppDatabase.createNewDb();
        
        // Effectuer la migration
        final migrationService = DataMigrationService(oldDb, newDb);
        
        // Export des données
        final exportData = await migrationService.exportAllData();
        
        // Import dans la nouvelle base
        await migrationService.importAllData(exportData);
        
        // Fermer les bases temporaires
        await oldDb.close();
        await newDb.close();
        
        debugPrint('✅ [MIGRATION] Migration terminée avec succès');
        
      } else {
        debugPrint('ℹ️ [MIGRATION] Ancienne base vide, pas de migration nécessaire');
        await oldDb.close();
      }
      
    } catch (e) {
      debugPrint('⚠️ [MIGRATION] Pas d\'ancienne base à migrer: $e');
      if (oldDb != null) {
        try {
          await oldDb.close();
        } catch (_) {}
      }
    }
  }
  
  /// Initialiser les autres services
  static Future<void> _initializeServices() async {
    debugPrint('⚙️ [INIT] Initialisation des services...');

    // ✅ Initialiser le ConfigService afin d'avoir une source centrale pour l'URL serveur
    _configService = ConfigService();
    await _configService!.init();
    debugPrint('✅ [INIT] ConfigService initialisé - server: ${_configService!.baseUrl}');

    // Ici vous pourriez initialiser :
    // - Services de notification
    // - Services de synchronisation
    // - Cache de l'application
    // - Services de géolocalisation
    // etc.

    debugPrint('✅ [INIT] Services initialisés');
  }
  
  /// Nettoyage en fin d'application
  static Future<void> cleanup() async {
    if (!_isInitialized) return;
    
    debugPrint('🧹 [CLEANUP] Nettoyage de l\'application...');
    
    try {
      // Fermer la base de données
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Nettoyer les données de test en mode debug
      if (kDebugMode) {
        await TestService.cleanupTestData();
      }
      
      _isInitialized = false;
      debugPrint('✅ [CLEANUP] Nettoyage terminé');
      
    } catch (e) {
      debugPrint('❌ [CLEANUP] Erreur de nettoyage: $e');
    }
  }
}