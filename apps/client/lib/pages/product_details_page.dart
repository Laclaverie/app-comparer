import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
// services
import 'package:client_price_comparer/services/product_details_service.dart';
// widgets
import 'package:client_price_comparer/widgets/product_details/product_header_widget.dart';
import 'package:client_price_comparer/widgets/product_details/product_current_price_widget.dart';
import 'package:client_price_comparer/widgets/product_details/price_chart_widget.dart';
import 'package:client_price_comparer/widgets/product_details/store_comparison_widget.dart';
import 'package:client_price_comparer/widgets/product_details/unit_price_comparison_widget.dart';
import 'package:client_price_comparer/widgets/product_details/product_statistics_widget.dart';
import 'package:client_price_comparer/widgets/product_details/product_action_buttons_widget.dart';
// models
import 'package:shared_models/models/product/productdto.dart'; // ✅ CHANGEMENT
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_models.dart';
import 'package:shared_models/models/price/price_point.dart';
import 'package:shared_models/models/product/product_statistics.dart';
import 'package:shared_models/models/unit/unit_type.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductDto product; // ✅ CHANGEMENT : ProductDto au lieu de Product
  final AppDatabase database;
  final ProductDisplayMode initialMode;
  final bool fromNotification;
  
  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.database,
    this.initialMode = ProductDisplayMode.minimal,
    this.fromNotification = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late ProductDetailsService _productDetailsService;
  bool _isLoading = true;
  ProductDto? _product; // ✅ CHANGEMENT : ProductDto au lieu de Product
  ProductDisplayMode _currentMode = ProductDisplayMode.minimal;
  String? selectedStore;

  // ✅ Cache des données en état local
  List<StorePrice>? _cachedStorePrices;
  final Map<String, List<PricePoint>> _cachedPriceHistory = {};
  bool _isLoadingStorePrices = false;
  bool _isLoadingPriceHistory = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _productDetailsService = ProductDetailsService(widget.database);
    _loadProduct();
    _loadInitialData();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    
    try {
      setState(() {
        _product = widget.product; // ✅ ProductDto
        _currentMode = widget.initialMode;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load product data: $e');
      }
    }
  }

  /// ✅ Charger les données initiales une seule fois
  Future<void> _loadInitialData() async {
    if (_product == null || _product!.id == null) return;

    try {
      // Charger les prix magasins
      await _loadStorePrices();
      
      // Charger l'historique complet (tous magasins)
      await _loadPriceHistory(null);
    } catch (e) {
      _showError('Failed to load data: $e');
    }
  }

  /// ✅ Charger les prix magasins sans reconstruction
  Future<void> _loadStorePrices() async {
    if (_cachedStorePrices != null || _product?.id == null) return;
    
    setState(() => _isLoadingStorePrices = true);
    
    try {
      final storePrices = await _productDetailsService.getStorePrices(_product!.id!);
      if (mounted) {
        setState(() {
          _cachedStorePrices = storePrices;
          _isLoadingStorePrices = false;
          _lastError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStorePrices = false;
          _lastError = e.toString();
        });
      }
    }
  }

  /// ✅ Charger l'historique sans reconstruction
  Future<void> _loadPriceHistory(String? storeFilter) async {
    if (_product?.id == null) return;
    
    final key = storeFilter ?? 'all';
    
    // Si déjà en cache, pas besoin de recharger
    if (_cachedPriceHistory.containsKey(key)) return;
    
    setState(() => _isLoadingPriceHistory = true);
    
    try {
      final priceHistory = await _productDetailsService.getPriceHistory(
        _product!.id!,
        storeFilter: storeFilter,
      );
      
      if (mounted) {
        setState(() {
          _cachedPriceHistory[key] = priceHistory;
          _isLoadingPriceHistory = false;
          _lastError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPriceHistory = false;
          _lastError = e.toString();
        });
      }
    }
  }

  /// ✅ Gestion de sélection sans reconstruction totale
  void _onStoreSelected(String storeName) async {
    // Toggle selection
    final newSelection = selectedStore == storeName ? null : storeName;
    
    setState(() {
      selectedStore = newSelection;
    });
    
    // Charger les données pour ce magasin si pas en cache
    if (newSelection != null) {
      await _loadPriceHistory(newSelection);
    }
  }

  /// ✅ Rafraîchir manuellement les données
  Future<void> _refreshData() async {
    // Vider les caches pour forcer le rechargement
    _cachedStorePrices = null;
    _cachedPriceHistory.clear();
    
    await _loadInitialData();
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == ProductDisplayMode.minimal 
          ? ProductDisplayMode.advanced 
          : ProductDisplayMode.minimal;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Product Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: Icon(_currentMode == ProductDisplayMode.minimal 
                ? Icons.analytics_outlined 
                : Icons.minimize_outlined),
            onPressed: _toggleMode,
            tooltip: _currentMode == ProductDisplayMode.minimal 
                ? 'Switch to Advanced mode' 
                : 'Switch to Minimal mode',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading product details...'),
                ],
              ),
            )
          : _product == null
              ? const Center(child: Text('Product not found'))
              : _buildMainContent(),
    );
  }

  /// ✅ Contenu principal sans FutureBuilder
  Widget _buildMainContent() {
    // Vérifier si on a les données de base
    if (_cachedStorePrices == null && _isLoadingStorePrices) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading store prices...'),
          ],
        ),
      );
    }

    if (_lastError != null && _cachedStorePrices == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_lastError'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Header
            ProductHeaderWidget(
              product: _product!, // ✅ ProductDto
            ),
            const SizedBox(height: 24),
            
            // Current Price Card
            if (_cachedStorePrices != null) ...[
              CurrentPriceCardWidget(
                priceHistory: _getCurrentPriceHistory(),
                storePrices: _cachedStorePrices!,
              ),
              const SizedBox(height: 24),
            ],
            
            // Store Comparison
            if (_cachedStorePrices != null) ...[
              StoreComparisonWidget(
                storePrices: _cachedStorePrices!,
                selectedStore: selectedStore,
                onStoreSelected: _onStoreSelected,
              ),
              const SizedBox(height: 24),
            ],
            
            // Price Chart
            _buildPriceChart(),
            
            // Section Advanced Mode
            if (_currentMode == ProductDisplayMode.advanced) ...[
              const SizedBox(height: 32),
              
              // Divider avec label
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ADVANCED ANALYSIS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              
              // Unit Price Comparison
              if (_cachedStorePrices != null) ...[
                UnitPriceComparisonWidget(
                  storePrices: _cachedStorePrices!,
                  selectedUnit: UnitType.per100g,
                ),
                const SizedBox(height: 24),
              ],

              // Product Statistics
              _buildProductStatistics(),
              const SizedBox(height: 24),

              // Product Actions
              ProductActionButtonsWidget(
                productId: _product!.id!,
                productDetailsService: _productDetailsService,
                onPriceAlert: _showPriceAlertDialog,
                onDelete: _showDeleteConfirmation,
              ),
              
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ Build statistics widget avec cache
  Widget _buildProductStatistics() {
    if (_product?.id == null) return const SizedBox.shrink();
    
    return FutureBuilder<ProductStatistics>(
      future: _productDetailsService.getProductStatistics(_product!.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return ProductStatisticsWidget(statistics: snapshot.data!);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  /// ✅ Prix alert avec null safety
  void _showPriceAlertDialog() {
    if (_product?.id == null) return;
    
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Set Price Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get notified when "${_product?.name ?? 'this product'}" drops below your target price.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target Price (€)',
                border: OutlineInputBorder(),
                prefixText: '€ ',
                helperText: 'You\'ll receive a notification when any store offers this price',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final priceText = controller.text.trim();
              final price = double.tryParse(priceText);
              
              if (price == null || price <= 0) {
                _showError('Please enter a valid price');
                return;
              }
              
              Navigator.pop(context);
              
              try {
                final success = await _productDetailsService.setPriceAlert(_product!.id!, price);
                if (success) {
                  _showSuccess('Price alert set for €${price.toStringAsFixed(2)}');
                } else {
                  _showError('Failed to set price alert');
                }
              } catch (e) {
                _showError('Error setting price alert: $e');
              }
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }

  /// ✅ Delete confirmation avec null safety
  void _showDeleteConfirmation() {
    if (_product?.id == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${_product?.name ?? 'this product'}"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All price history and alerts will be permanently removed.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final success = await _productDetailsService.deleteProduct(_product!.id!);
                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('Product deleted successfully');
                  }
                } else {
                  _showError('Failed to delete product');
                }
              } catch (e) {
                _showError('Error deleting product: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// ✅ Obtenir l'historique actuel selon le filtre
  List<PricePoint> _getCurrentPriceHistory() {
    final key = selectedStore ?? 'all';
    return _cachedPriceHistory[key] ?? [];
  }

  // ✅ Build price chart avec indicateur de chargement
  Widget _buildPriceChart() {
    final currentHistory = _getCurrentPriceHistory();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header du graphique
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Price History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingPriceHistory)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Graphique ou placeholder
            if (currentHistory.isNotEmpty)
              PriceChartWidget(
                priceHistory: currentHistory,
                selectedStore: selectedStore,
              )
            else if (_isLoadingPriceHistory)
              const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading price history...'),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No price history available'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}