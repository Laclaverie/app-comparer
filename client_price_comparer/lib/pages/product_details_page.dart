import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/models/price_models.dart';
import 'package:client_price_comparer/services/product_details_service.dart';
import 'package:client_price_comparer/widgets/product_details/product_header_widget.dart';
import 'package:client_price_comparer/widgets/product_details/product_current_price_widget.dart';
import 'package:client_price_comparer/widgets/product_details/price_chart_widget.dart';
import 'package:client_price_comparer/widgets/product_details/store_comparison_widget.dart';

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
  late ProductDisplayMode _currentMode;
  late final ProductDetailsService _service;
  
  List<PricePoint> _priceHistory = [];
  List<StorePrice> _storePrices = [];
  ProductStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _service = ProductDetailsService(widget.database);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final priceHistory = await _service.getPriceHistory(widget.product.id);
      final storePrices = await _service.getStorePrices(widget.product.id);
      final statistics = await _service.getProductStatistics(widget.product.id);
      
      if (mounted) {
        setState(() {
          _priceHistory = priceHistory;
          _storePrices = storePrices;
          _statistics = statistics;
          _isLoading = false;
        });
      }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMode == ProductDisplayMode.minimal 
            ? 'Product Details' 
            : 'Advanced Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_currentMode == ProductDisplayMode.minimal 
                ? Icons.analytics 
                : Icons.minimize),
            onPressed: _toggleMode,
            tooltip: _currentMode == ProductDisplayMode.minimal 
                ? 'Advanced mode' 
                : 'Minimal mode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentMode == ProductDisplayMode.minimal 
              ? _buildMinimalView() 
              : _buildAdvancedView(),
    );
  }

  Widget _buildMinimalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductHeaderWidget(
            product: widget.product,
            fromNotification: widget.fromNotification,
          ),
          const SizedBox(height: 24),
          
          CurrentPriceCardWidget(
            priceHistory: _priceHistory,
            storePrices: _storePrices,
          ),
          const SizedBox(height: 24),
          
          PriceChartWidget(priceHistory: _priceHistory),
          const SizedBox(height: 24),
          
          StoreComparisonWidget(storePrices: _storePrices),
          const SizedBox(height: 24),
          
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAdvancedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductHeaderWidget(
            product: widget.product,
            fromNotification: widget.fromNotification,
          ),
          const SizedBox(height: 24),
          
          if (_statistics != null) _buildDetailedStatistics(),
          const SizedBox(height: 24),
          
          _buildAdvancedOptions(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await _service.addToFavorites(widget.product.id);
              if (success) {
                _showSuccess('Added to favorites');
              } else {
                _showError('Failed to add to favorites');
              }
            },
            icon: const Icon(Icons.favorite_border),
            label: const Text('Add to Favorites'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showPriceAlertDialog();
            },
            icon: const Icon(Icons.notifications),
            label: const Text('Price Alert'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatistics() {
    final stats = _statistics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatRow('Average Price', '€${stats.averagePrice.toStringAsFixed(2)}'),
            _buildStatRow('Median Price', '€${stats.medianPrice.toStringAsFixed(2)}'),
            _buildStatRow('Price Variance', '±€${stats.priceVariance.toStringAsFixed(2)}'),
            
            const SizedBox(height: 12),
            
            // Best deal with explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.green[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Best Deal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.bestDealExplanation,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Worst deal with explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Avoid This Deal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.worstDealExplanation,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product Info'),
              onTap: () {
                // TODO: Navigate to edit page
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Product'),
              onTap: () {
                // TODO: Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Full Price History'),
              onTap: () {
                // TODO: Show full history
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product', style: TextStyle(color: Colors.red)),
              onTap: _showDeleteConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceAlertDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Price Alert'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Price (€)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price != null) {
                Navigator.pop(context);
                final success = await _service.setPriceAlert(widget.product.id, price);
                if (success) {
                  _showSuccess('Price alert set for €${price.toStringAsFixed(2)}');
                } else {
                  _showError('Failed to set price alert');
                }
              }
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${widget.product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _service.deleteProduct(widget.product.id);
              if (success) {
                Navigator.pop(context); // Go back to previous screen
                _showSuccess('Product deleted');
              } else {
                _showError('Failed to delete product');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}