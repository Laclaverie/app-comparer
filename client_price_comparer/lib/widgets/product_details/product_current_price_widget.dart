import 'package:flutter/material.dart';
import 'package:client_price_comparer/models/store/store_price.dart';
import 'package:client_price_comparer/models/price/price_point.dart';

class CurrentPriceCardWidget extends StatelessWidget {
  final List<PricePoint> priceHistory;
  final List<StorePrice> storePrices;

  const CurrentPriceCardWidget({
    super.key,
    required this.priceHistory,
    required this.storePrices,
  });

  @override
  Widget build(BuildContext context) {
    if (storePrices.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get best deal (lowest effective price)
    final bestDeal = storePrices.reduce(
      (a, b) => a.effectivePrice < b.effectivePrice ? a : b
    );
    
    // Compare with user's current store if applicable
    final currentStore = storePrices.where((s) => s.isCurrentStore).firstOrNull;
    
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Best Unit Price Available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Best deal details
            Row(
              children: [
                Text(
                  '€${bestDeal.effectivePrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '/unit',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  'at ${bestDeal.storeName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            
            // Show regular price if there's a promotion
            if (bestDeal.promotion != null && bestDeal.promotion!.isValid) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Regular: €${bestDeal.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${bestDeal.promotion!.getSavingsPercentage(bestDeal.price).toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                bestDeal.promotion!.description,
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // Comparison with current store
            if (currentStore != null && currentStore != bestDeal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your current store (${currentStore.storeName}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '€${currentStore.effectivePrice.toStringAsFixed(2)}/unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Save €${(currentStore.effectivePrice - bestDeal.effectivePrice).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}