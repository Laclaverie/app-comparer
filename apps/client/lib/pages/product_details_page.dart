import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/product_details_service.dart';
import 'package:shared_models/models/product/productdto.dart';

import 'package:client_price_comparer/widgets/product_info_card.dart';
import 'package:client_price_comparer/widgets/store_prices_card.dart';
import 'package:client_price_comparer/widgets/price_history_card.dart';

enum ProductDisplayModeTmp { minimal, advanced }

class ProductDetailsPage extends StatefulWidget {
  final ProductDto product;
  final AppDatabase database;
  final ProductDisplayModeTmp initialMode;
  final bool fromNotification;
  
  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.database,
    this.initialMode = ProductDisplayModeTmp.minimal,
    this.fromNotification = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late ProductDetailsService _productDetailsService;
  ProductDto? _product;
  ProductDisplayModeTmp _currentMode = ProductDisplayModeTmp.minimal;

  @override
  void initState() {
    super.initState();
    _productDetailsService = ProductDetailsService(widget.database);
    _product = widget.product;
    _currentMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_product?.name ?? 'Product Details'),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      actions: [
        IconButton(
          icon: Icon(_currentMode == ProductDisplayModeTmp.minimal 
              ? Icons.analytics_outlined 
              : Icons.minimize_outlined),
          onPressed: _toggleMode,
          tooltip: _currentMode == ProductDisplayModeTmp.minimal 
              ? 'Switch to Advanced mode' 
              : 'Switch to Minimal mode',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_product == null) {
      return const Center(child: Text('Product not found'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductInfoCard(product: _product!),
            const SizedBox(height: 16),
            ProductStatusCard(product: _product!, currentMode: _currentMode),
            const SizedBox(height: 16),
            StorePricesCard(
              product: _product!,
              isAdvancedMode: _currentMode == ProductDisplayModeTmp.advanced,
            ),
            const SizedBox(height: 16),
            PriceHistoryCard(
              product: _product!,
              isAdvancedMode: _currentMode == ProductDisplayModeTmp.advanced,
            ),
            const SizedBox(height: 16),
            // ✅ ÉTAPE 5 : Ajoutera AdvancedModeCard
          ],
        ),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == ProductDisplayModeTmp.minimal 
          ? ProductDisplayModeTmp.advanced 
          : ProductDisplayModeTmp.minimal;
    });
  }

  Future<void> _refreshData() async {
    // ✅ IMPLÉMENTATION SIMPLE POUR L'INSTANT
    setState(() {}); // Rebuild
  }
}

/// ✅ COMPOSANT : Statut du produit
class ProductStatusCard extends StatelessWidget {
  final ProductDto product;
  final ProductDisplayModeTmp currentMode;
  
  const ProductStatusCard({
    super.key,
    required this.product,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  product.isActive ? Icons.check_circle : Icons.cancel,
                  color: product.isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  product.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: product.isActive ? Colors.green : Colors.red,
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
                  currentMode == ProductDisplayModeTmp.minimal 
                      ? Icons.visibility 
                      : Icons.analytics,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Display Mode: ${currentMode == ProductDisplayModeTmp.minimal ? 'Minimal' : 'Advanced'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}