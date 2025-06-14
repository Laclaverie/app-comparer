import 'package:flutter/material.dart';
import 'package:shared_models/models/store/store_price.dart';

class StoreComparisonWidget extends StatelessWidget {
  final List<StorePrice> storePrices;
  final Function(String)? onStoreSelected;
  final String? selectedStore;

  const StoreComparisonWidget({
    super.key,
    required this.storePrices,
    this.onStoreSelected,
    this.selectedStore,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by effective price for better display
    final sortedPrices = List<StorePrice>.from(storePrices)
      ..sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));

    return Card(
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
                  'Store Price Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedStore != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(selectedStore!),
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    onDeleted: () => onStoreSelected?.call(''),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            ...sortedPrices.asMap().entries.map((entry) {
              final index = entry.key;
              final storePrice = entry.value;
              final isSelected = selectedStore == storePrice.storeName;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onStoreSelected?.call(storePrice.storeName),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : null,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Badge pour le meilleur deal
                            if (index == 0) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
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
                            
                            const SizedBox(width: 8),
                            
                            // Nom du magasin
                            Expanded(
                              child: Text(
                                storePrice.storeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Theme.of(context).primaryColor : null,
                                ),
                              ),
                            ),
                            
                            // Prix avec effet de promotion
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (storePrice.hasActivePromotion) ...[
                                  Text(
                                    '€${storePrice.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '€${storePrice.effectivePrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '€${storePrice.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            // Icône de sélection
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        
                        // Promotion details
                        if (storePrice.hasActivePromotion) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Text(
                              storePrice.promotion!.description,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        
                        // Last updated
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated ${_formatTimestamp(storePrice.lastUpdated)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            if (selectedStore != null) ...[
              const SizedBox(height: 12),
              Text(
                '💡 Tip: Click the chart points to see exact prices',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}