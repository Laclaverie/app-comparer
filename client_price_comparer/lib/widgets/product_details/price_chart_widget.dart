import 'package:flutter/material.dart';
import 'package:client_price_comparer/models/price_models.dart';

class PriceChartWidget extends StatelessWidget {
  final List<PricePoint> priceHistory;

  const PriceChartWidget({
    super.key,
    required this.priceHistory,
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
              'Price Evolution',
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
                painter: PriceChartPainter(priceHistory),
                size: const Size(double.infinity, 200),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${priceHistory.length} days ago',
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
      // If all prices are the same, draw a horizontal line
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