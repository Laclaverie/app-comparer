import 'package:flutter/material.dart';
import 'package:client_price_comparer/widgets/product_details/unit_price_display_widget.dart';
import 'package:client_price_comparer/models/store_price.dart';

class StoreComparisonWidget extends StatelessWidget {
  final List<StorePrice> storePrices;

  const StoreComparisonWidget({
    super.key,
    required this.storePrices,
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
            Text(
              'Unit Price Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All prices shown are per unit. Promotion conditions apply.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            
            ...sortedPrices.asMap().entries.map((entry) {
              final index = entry.key;
              final store = entry.value;
              final isBestDeal = index == 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: UnitPriceDisplayWidget(
                  storePrice: store,
                  isHighlighted: isBestDeal,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}