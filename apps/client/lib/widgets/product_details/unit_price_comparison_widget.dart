// apps/client/lib/widgets/product_details/unit_price_comparison_widget.dart
import 'package:flutter/material.dart';
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/unit/unit_type.dart';

class UnitPriceComparisonWidget extends StatelessWidget {
  final List<StorePrice> storePrices;
  final UnitType selectedUnit;

  const UnitPriceComparisonWidget({
    super.key,
    required this.storePrices,
    required this.selectedUnit,
  });

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}