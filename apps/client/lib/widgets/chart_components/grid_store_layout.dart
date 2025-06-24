// lib/widgets/chart_components/grid_store_layout.dart - Widget spécialisé
import 'package:client_price_comparer/services/charts/store_comparison_service.dart';
import 'package:client_price_comparer/widgets/chart_components/store_chip.dart';
import 'package:flutter/material.dart';

class GridStoreLayout extends StatelessWidget {
  final Map<int, StoreChartData> storeData;
  final Map<int, bool> visibility;
  final Set<int> bestPriceStoreIds;
  final bool isCompactMode;
  final Function(int, bool) onStoreToggled;

  const GridStoreLayout({
    super.key,
    required this.storeData,
    required this.visibility,
    required this.bestPriceStoreIds,
    required this.isCompactMode,
    required this.onStoreToggled,
  });

  @override
  Widget build(BuildContext context) {
    final storeCount = storeData.length;
    final crossAxisCount = storeCount == 1 ? 1 : 2;
    final rowCount = (storeCount / crossAxisCount).ceil();
    final itemHeight = isCompactMode ? 36.0 : 40.0;
    final spacing = 8.0;
    final gridHeight = (rowCount * itemHeight) + ((rowCount - 1) * spacing);
      
    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isCompactMode ? 3.5 : 3.2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: storeCount,
        itemBuilder: (context, index) {
          final entry = storeData.entries.toList()[index];
          
          return StoreChip(
            storeData: entry.value,
            isVisible: visibility[entry.key] ?? false,
            isBestPrice: bestPriceStoreIds.contains(entry.key),
            isCompactMode: isCompactMode,
            onToggled: (isVisible) => onStoreToggled(entry.key, isVisible),
          );
        },
      ),
    );
  }
}