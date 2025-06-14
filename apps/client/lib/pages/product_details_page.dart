import 'dart:async' show TimeoutException;

import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/product_details_service.dart';
import 'package:shared_models/models/price/price_promotion.dart' show PricePromotion;
import 'package:shared_models/models/product/productdto.dart';
import 'package:shared_models/models/promotion/promotion_type.dart';
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_point.dart';

enum ProductDisplayModeTmp { minimal, advanced }

class ProductDetailsPage extends StatefulWidget {
  final ProductDto product;
  final AppDatabase database;
  final ProductDisplayModeTmp
 initialMode;
  final bool fromNotification;
  
  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.database,
    this.initialMode = ProductDisplayModeTmp
  .minimal,
    this.fromNotification = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isLoading = false;
  
  late ProductDetailsService _productDetailsService;
  ProductDto? _product;
  ProductDisplayModeTmp
 _currentMode = ProductDisplayModeTmp
.minimal;
  String? selectedStore;

  // Cache des données en état local
  List<StorePrice>? _cachedStorePrices;
  final Map<String, List<PricePoint>> _cachedPriceHistory = {};
  bool _isLoadingStorePrices = false;
  bool _isLoadingPriceHistory = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    debugPrint('🏗️ [DETAILS] initState début...');
    
    try {
      _productDetailsService = ProductDetailsService(widget.database);
      debugPrint('✅ [DETAILS] ProductDetailsService créé');
      
      _product = widget.product;
      _currentMode = widget.initialMode;
      debugPrint('✅ [DETAILS] Variables initialisées');
      
      // ✅ SIMPLIFICATION : Charger les données APRÈS le build initial
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('📅 [DETAILS] PostFrameCallback - Chargement données...');
        _loadInitialDataSafely();
      });
      
      debugPrint('✅ [DETAILS] initState terminé');
    } catch (e) {
      debugPrint('❌ [DETAILS] Erreur initState: $e');
    }
  }

  /// ✅ NOUVEAU : Chargement sécurisé des données
  Future<void> _loadInitialDataSafely() async {
    if (!mounted) {
      debugPrint('⚠️ [DETAILS] Widget non monté, abandon chargement');
      return;
    }

    try {
      debugPrint('🔄 [DETAILS] Début chargement données...');
      await _loadInitialData();
      debugPrint('✅ [DETAILS] Chargement données terminé');
    } catch (e) {
      debugPrint('❌ [DETAILS] Erreur chargement données: $e');
      if (mounted) {
        _showError('Erreur chargement: $e');
      }
    }
  }

  /// ✅ SIMPLIFICATION : Version minimale
  Future<void> _loadInitialData() async {
    if (_product == null || _product!.id == null) {
      debugPrint('⚠️ [DETAILS] Pas de produit ou ID pour charger les données');
      return;
    }

    debugPrint('📊 [DETAILS] Chargement initial pour produit ${_product!.id}');

    try {
      // ✅ RÉACTIVER PROGRESSIVEMENT : D'abord les prix magasins
      await _loadStorePrices();
      debugPrint('✅ [DETAILS] Chargement initial terminé');
    } catch (e) {
      debugPrint('❌ [DETAILS] Erreur chargement initial: $e');
      // Ne pas throw l'erreur pour éviter le freeze
    }
  }

  /// ✅ VERSION DEV : Directement simuler les données pour éviter le freeze
Future<void> _loadStorePrices() async {
  if (_product?.id == null) {
    debugPrint('⚠️ [STORES] Pas d\'ID produit pour charger les prix magasins');
    return;
  }
  
  // Si déjà en cache, pas besoin de recharger
  if (_cachedStorePrices != null) {
    debugPrint('ℹ️ [STORES] Prix magasins déjà en cache');
    return;
  }
  
  setState(() => _isLoadingStorePrices = true);
  
  debugPrint('🏪 [STORES] Mode développement - simulation directe des prix magasins');
  
  // ✅ TEMPORAIRE : Simuler directement pour éviter le freeze du service
  await _simulateStorePrices();
}

/// ✅ CORRECTION COMPLÈTE : Simuler des prix magasins avec promotions
Future<void> _simulateStorePrices() async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simuler délai réseau
  
  if (mounted) {
    setState(() {
      _cachedStorePrices = [
        StorePrice(
          storeName: 'Carrefour',
          price: 2.45,
          isCurrentStore: false,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
          promotion: null, // Pas de promotion
        ),
        StorePrice(
          storeName: 'Leclerc',
          price: 2.32,
          isCurrentStore: true, // Magasin actuel
          lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
          promotion: null,
        ),
        StorePrice(
          storeName: 'Auchan',
          price: 2.58,
          isCurrentStore: false,
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          promotion: null,
        ),
        StorePrice(
          storeName: 'Intermarché',
          price: 2.29,
          isCurrentStore: false,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 8)),
          promotion: PricePromotion(
            type: PromotionType.fixedDiscount,
            description: '-15% cette semaine',
            parameters: {
              'discountPercentage': 15.0,
              'discountAmount': 0.40,
              'minPurchase': null,
              'maxDiscount': null,
              'category': 'weekly_discount',
              'source': 'store_flyer',
            }, // ✅ Paramètres détaillés de la promotion
            validFrom: DateTime.now().subtract(const Duration(days: 1)),
            validTo: DateTime.now().add(const Duration(days: 3)),
            originalPrice: 2.69,
          ),
        ),
        // ✅ BONUS : Ajouter un autre magasin avec promotion différente
        StorePrice(
          storeName: 'Super U',
          price: 2.15,
          isCurrentStore: false,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
          promotion: PricePromotion(
            type: PromotionType.fixedDiscount,
            description: '2ème à -50%',
            parameters: {
              'discountPercentage': 50.0,
              'discountAmount': null,
              'minPurchase': 2.0, // Minimum 2 articles
              'maxDiscount': null,
              'category': 'bulk_discount',
              'source': 'loyalty_program',
            },
            validFrom: DateTime.now().subtract(const Duration(hours: 12)),
            validTo: DateTime.now().add(const Duration(days: 5)),
            originalPrice: 2.45,
          ),
        ),
      ];
      _isLoadingStorePrices = false;
    });
    
    debugPrint('✅ [STORES] 5 prix magasins simulés ajoutés (avec promotions)');
  }
}
  /// ✅ Rafraîchir manuellement les données
  Future<void> _refreshData() async {
    debugPrint('🔄 [REFRESH] Rafraîchissement des données');
    
    try {
      // Vider les caches pour forcer le rechargement
      _cachedStorePrices = null;
      _cachedPriceHistory.clear();
      
      // Recharger les données
      await _loadInitialData();
      
      debugPrint('✅ [REFRESH] Rafraîchissement terminé');
      
      if (mounted) {
        _showSuccess('✅ Data refreshed successfully');
      }
    } catch (e) {
      debugPrint('❌ [REFRESH] Erreur: $e');
      if (mounted) {
        _showError('❌ Refresh failed: $e');
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == ProductDisplayModeTmp
    .minimal 
          ? ProductDisplayModeTmp
        .advanced 
          : ProductDisplayModeTmp
        .minimal;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [DETAILS] Build début...');
    
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(_product?.name ?? 'Product Details'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          actions: [
            IconButton(
              icon: Icon(_currentMode == ProductDisplayModeTmp
            .minimal 
                  ? Icons.analytics_outlined 
                  : Icons.minimize_outlined),
              onPressed: () {
                debugPrint('🔄 [DETAILS] Toggle mode');
                _toggleMode();
              },
              tooltip: _currentMode == ProductDisplayModeTmp
            .minimal 
                  ? 'Switch to Advanced mode' 
                  : 'Switch to Minimal mode',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                debugPrint('🔄 [DETAILS] Refresh demandé');
                _refreshData();
              },
              tooltip: 'Refresh data',
            ),
          ],
        ),
        body: _buildBody(),
      );
    } catch (e) {
      debugPrint('❌ [DETAILS] Erreur build: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur affichage: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// ✅ VERSION ULTRA-SIMPLIFIÉE : Body sécurisé
  Widget _buildBody() {
    debugPrint('🎨 [DETAILS] Build body - version simplifiée...');
    
    if (_product == null) {
      debugPrint('⚠️ [DETAILS] Pas de produit à afficher');
      return const Center(child: Text('Product not found'));
    }

    debugPrint('🎨 [DETAILS] Affichage produit: ${_product!.name}');

    // ✅ VERSION ULTRA-SIMPLIFIÉE sans widgets externes
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ CARD BASIQUE avec infos produit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      _product!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    if (_product!.description != null) ...[
                      Text(
                        _product!.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Code-barres
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Code-barres: ${_product!.barcode}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Image (si disponible)
                    if (_product!.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _product!.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('Loading image...'),
                                  ],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 48),
                                    SizedBox(height: 8),
                                    Text('Image not available'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Placeholder si pas d'image
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No image available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ CARD STATUT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Product Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(
                          _product!.isActive ? Icons.check_circle : Icons.cancel,
                          color: _product!.isActive ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _product!.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: _product!.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Mode actuel
                    Row(
                      children: [
                        Icon(
                          _currentMode == ProductDisplayModeTmp
                        .minimal 
                              ? Icons.visibility 
                              : Icons.analytics,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Display Mode: ${_currentMode == ProductDisplayModeTmp
                        .minimal ? 'Minimal' : 'Advanced'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ✅ PLACEHOLDER pour les fonctionnalités futures
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 48,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Price History & Store Comparison',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming soon! Price tracking and store comparison features will be available here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showSuccess('Feature coming soon!');
                      },
                      icon: const Icon(Icons.timeline),
                      label: const Text('View Price History'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ✅ AJOUT : Informations détaillées du produit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de la section
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Product Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ID du produit (si disponible)
                    if (_product!.id != null) ...[
                      _buildInfoRow(
                        icon: Icons.tag,
                        label: 'Product ID',
                        value: '#${_product!.id}',
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Brand et Category (si disponibles)
                    if (_product!.brandId != null) ...[
                      _buildInfoRow(
                        icon: Icons.branding_watermark,
                        label: 'Brand ID',
                        value: '#${_product!.brandId}',
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (_product!.categoryId != null) ...[
                      _buildInfoRow(
                        icon: Icons.category,
                        label: 'Category ID',
                        value: '#${_product!.categoryId}',
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Divider avant les dates
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Date d'ajout
                    _buildInfoRow(
                      icon: Icons.schedule,
                      label: 'Added',
                      value: _formatDate(_product!.createdAt),
                    ),
                    
                    // Date de modification (si différente)
                    if (_product!.updatedAt != null && 
                        _product!.updatedAt != _product!.createdAt) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: _formatDate(_product!.updatedAt),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Remplacer le placeholder par une vraie section prix :
            if (_cachedStorePrices != null && _cachedStorePrices!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Store Prices',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // ✅ AJOUT : Indicateur du nombre de magasins
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_cachedStorePrices!.length} stores',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ AMÉLIORATION : Trier par prix (meilleur prix en premier)
                      ...(_cachedStorePrices!..sort((a, b) => a.price.compareTo(b.price)))
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final storePrice = entry.value;
                        final isLowestPrice = index == 0;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLowestPrice 
                                  ? Colors.green.withOpacity(0.05)
                                  : storePrice.isCurrentStore
                                      ? Theme.of(context).primaryColor.withOpacity(0.05)
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLowestPrice 
                                    ? Colors.green.withOpacity(0.3)
                                    : storePrice.isCurrentStore
                                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // ✅ Icône avec couleur conditionnelle
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isLowestPrice 
                                        ? Colors.green.withOpacity(0.1)
                                        : storePrice.isCurrentStore
                                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isLowestPrice 
                                        ? Icons.emoji_events // Trophée pour le meilleur prix
                                        : storePrice.isCurrentStore
                                            ? Icons.location_on // Pin pour magasin actuel
                                            : Icons.storefront,
                                    color: isLowestPrice 
                                        ? Colors.green
                                        : storePrice.isCurrentStore
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // ✅ Informations magasin
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            storePrice.storeName,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(width: 8),
                                          // ✅ Badges
                                          if (isLowestPrice) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'BEST',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (storePrice.isCurrentStore && !isLowestPrice) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'CURRENT',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Updated: ${_formatDate(storePrice.lastUpdated)}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          // ✅ AJOUT : Affichage promotion
                                          if (storePrice.promotion != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'PROMO',
                                                style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      // ✅ Détail promotion
                                      if (storePrice.promotion != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          storePrice.promotion!.description,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.orange[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // ✅ Prix avec style conditionnel
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '€${storePrice.price.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isLowestPrice 
                                            ? Colors.green
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    // ✅ Prix original si promotion
                                    if (storePrice.promotion?.originalPrice != null) ...[
                                      Text(
                                        '€${storePrice.promotion!.originalPrice!.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ));
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ] else if (_isLoadingStorePrices) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Loading store prices...'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.store_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No store prices available yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _loadStorePrices(), // Réessayer
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check for prices'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
  if (date == null) return 'Unknown';
  
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// ✅ HELPER : Construire une ligne d'information
Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: Colors.grey[600],
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
}