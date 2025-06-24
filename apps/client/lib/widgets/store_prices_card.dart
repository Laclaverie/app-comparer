// lib/widgets/store_prices_card.dart
import 'package:flutter/material.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'store_price_item.dart';
import 'store_price_stats.dart';
import 'shared/mock_data_helpers.dart';

class StorePricesCard extends StatefulWidget {
  final ProductDto product;
  final bool isAdvancedMode;

  const StorePricesCard({
    super.key,
    required this.product,
    required this.isAdvancedMode,
  });

  @override
  State<StorePricesCard> createState() => _StorePricesCardState();
}

class _StorePricesCardState extends State<StorePricesCard> {
  List<PriceHistoryDto>? _currentPrices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.store, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Prix actuels par magasin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentPrices,
            tooltip: 'Actualiser les prix',
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState(context);
    if (_currentPrices == null || _currentPrices!.isEmpty) return _buildEmptyState(context);
    
    return _buildPricesList(context);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des prix...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Colors.red[600])),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadCurrentPrices,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.price_change_outlined, size: 48, color: Colors.orange[600]),
            const SizedBox(height: 16),
            Text(
              'Aucun prix disponible',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les prix de ce produit ne sont pas encore référencés',
              style: TextStyle(color: Colors.orange[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _onAddPricePressed(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un prix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricesList(BuildContext context) {
    final sortedPrices = List<PriceHistoryDto>.from(_currentPrices!)
      ..sort((a, b) => a.price.compareTo(b.price));

    return Column(
      children: [
        // Statistiques en mode avancé
        if (widget.isAdvancedMode) ...[
          StorePriceStats(prices: sortedPrices),
          const SizedBox(height: 16),
        ],
        
        // Liste des prix
        ...sortedPrices.asMap().entries.map((entry) {
          final index = entry.key;
          final price = entry.value;
          final isLowest = index == 0;
          final isHighest = index == sortedPrices.length - 1 && sortedPrices.length > 1;
          
          return Padding(
            padding: EdgeInsets.only(bottom: index == sortedPrices.length - 1 ? 0 : 8),
            child: StorePriceItem(
              price: price,
              isLowest: isLowest,
              isHighest: isHighest,
              isAdvancedMode: widget.isAdvancedMode,
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _loadCurrentPrices() async {
    print('🔍 STORE_PRICES: Loading current prices for product ${widget.product.barcode}');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ TODO : Remplacer par l'appel API réel
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      // ✅ DONNÉES MOCK pour test
      _currentPrices = MockDataHelpers.generateMockPrices(widget.product.id!);
      
      print('✅ STORE_PRICES: Loaded ${_currentPrices!.length} prices');
    } catch (e) {
      print('❌ STORE_PRICES ERROR: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onAddPricePressed(BuildContext context) {
    // ✅ TODO : Implémentation ajout de prix
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout de prix - À implémenter')),
    );
  }
}