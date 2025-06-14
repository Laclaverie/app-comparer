import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_point.dart';

class PriceChartWidget extends StatelessWidget {
  final List<PricePoint> priceHistory;
  final String? selectedStore;

  const PriceChartWidget({
    super.key,
    required this.priceHistory,
    this.selectedStore,
  });

  @override
  Widget build(BuildContext context) {
    final filteredHistory = selectedStore != null
        ? priceHistory.where((point) => point.storeName == selectedStore).toList()
        : _getAveragePrices();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedStore != null
                  ? 'Price Evolution - $selectedStore'
                  : 'Price Evolution - Average',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: CustomPaint(
                painter: PriceChartPainter(filteredHistory),
                size: const Size(double.infinity, 200),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '30 days ago',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PricePoint> _getAveragePrices() {
    final Map<String, List<PricePoint>> pricesByDate = {};
    
    for (final point in priceHistory) {
      final dateKey = point.date.toIso8601String().split('T')[0];
      pricesByDate.putIfAbsent(dateKey, () => []).add(point);
    }
    
    return pricesByDate.entries.map((entry) {
      final avgPrice = entry.value.map((p) => p.price).reduce((a, b) => a + b) / entry.value.length;
      return PricePoint(
        date: DateTime.parse(entry.key),
        price: avgPrice,
        storeName: 'Average',
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}

class PriceChartPainter extends CustomPainter {
  final List<PricePoint> priceHistory;

  PriceChartPainter(this.priceHistory);

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    final minPrice = priceHistory.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = priceHistory.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    
    if (priceRange == 0) {
      final y = size.height / 2;
      path.moveTo(0, y);
      path.lineTo(size.width, y);
    } else {
      for (int i = 0; i < priceHistory.length; i++) {
        final x = (i / (priceHistory.length - 1)) * size.width;
        final y = size.height - ((priceHistory[i].price - minPrice) / priceRange) * size.height;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}