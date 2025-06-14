import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:provider/provider.dart';
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
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_models.dart';
import 'package:shared_models/models/price/price_point.dart';
import 'package:shared_models/models/product/product_statistics.dart';
import 'package:shared_models/models/unit/unit_type.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
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
  Product? _product;
  ProductDisplayMode _currentMode = ProductDisplayMode.minimal;
  String? selectedStore; // État pour le magasin sélectionné

  @override
  void initState() {
    super.initState();
    _productDetailsService = ProductDetailsService(
      widget.database,
    );
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    
    try {
      // Utiliser directement le produit passé en paramètre
      setState(() {
        _product = widget.product;
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
            onPressed: () {
              setState(() {
                // Force rebuild to refresh data
              });
            },
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Product not found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This product might have been removed or is temporarily unavailable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<StorePrice>>(
                  future: _productDetailsService.getStorePrices(_product!.id),
                  builder: (context, storePricesSnapshot) {
                    if (storePricesSnapshot.connectionState == ConnectionState.waiting) {
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
                    
                    if (storePricesSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading prices',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              storePricesSnapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!storePricesSnapshot.hasData || storePricesSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No store prices available',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Price data will appear here once stores start offering this product.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return FutureBuilder<List<PricePoint>>(
                      future: _productDetailsService.getPriceHistory(
                        _product!.id,
                        storeFilter: selectedStore, // Filtre par magasin sélectionné
                      ),
                      builder: (context, priceHistorySnapshot) {
                        if (priceHistorySnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading price history...'),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              // Force rebuild to refresh all data
                            });
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Product Header avec image et infos de base
                                ProductHeaderWidget(
                                  product: _product!,
                                  fromNotification: widget.fromNotification,
                                ),
                                const SizedBox(height: 24),
                                
                                // Current Price Card - prix actuel et tendance
                                CurrentPriceCardWidget(
                                  priceHistory: priceHistorySnapshot.data ?? [],
                                  storePrices: storePricesSnapshot.data!,
                                ),
                                const SizedBox(height: 24),
                                
                                // Store Comparison avec interactivité
                                StoreComparisonWidget(
                                  storePrices: storePricesSnapshot.data!,
                                  selectedStore: selectedStore,
                                  onStoreSelected: (storeName) {
                                    setState(() {
                                      // Toggle: même magasin = désélectionner, autre = sélectionner
                                      selectedStore = selectedStore == storeName ? null : storeName;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Price Chart avec filtre par magasin
                                PriceChartWidget(
                                  priceHistory: priceHistorySnapshot.data ?? [],
                                  selectedStore: selectedStore, // Passe le filtre au graphique
                                ),
                                
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
                                  UnitPriceComparisonWidget(
                                    storePrices: storePricesSnapshot.data!,
                                    selectedUnit: UnitType.per100g,
                                  ),
                                  const SizedBox(height: 24),

                                  // Product Statistics
                                  FutureBuilder<ProductStatistics>(
                                    future: _productDetailsService.getProductStatistics(_product!.id),
                                    builder: (context, statsSnapshot) {
                                      if (statsSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Card(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                        );
                                      }
                                      
                                      if (statsSnapshot.hasData) {
                                        return ProductStatisticsWidget(
                                          statistics: statsSnapshot.data!,
                                        );
                                      }
                                      
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Product Actions
                                  ProductActionButtonsWidget(
                                    productId: _product!.id,
                                    productDetailsService: _productDetailsService,
                                    onPriceAlert: _showPriceAlertDialog,
                                    onDelete: _showDeleteConfirmation,
                                  ),
                                  
                                  // Extra spacing at bottom
                                  const SizedBox(height: 32),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  /// Affiche le dialog pour définir une alerte de prix
  void _showPriceAlertDialog() {
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
                final success = await _productDetailsService.setPriceAlert(_product!.id, price);
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

  /// Affiche le dialog de confirmation pour supprimer le produit
  void _showDeleteConfirmation() {
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
                final success = await _productDetailsService.deleteProduct(_product!.id);
                if (success) {
                  if (mounted) {
                    Navigator.pop(context); // Retour à la page précédente
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

  @override
  void dispose() {
    super.dispose();
  }
}