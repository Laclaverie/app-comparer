import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'shared/price_formatting_helpers.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryDto> priceHistory;
  final int selectedPeriodDays;

  const PriceHistoryChart({
    super.key,
    required this.priceHistory,
    required this.selectedPeriodDays,
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildChartHeader(context),
          const SizedBox(height: 16),
          Expanded(child: _buildChart(context)),
          const SizedBox(height: 8),
          _buildChartFooter(context),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Pas assez de données',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader(BuildContext context) {
    final stats = _calculateChartStats();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Min: ${PriceFormattingHelpers.formatPrice(stats.minPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Max: ${PriceFormattingHelpers.formatPrice(stats.maxPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Moyenne',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              PriceFormattingHelpers.formatPrice(stats.avgPrice),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final stats = _calculateChartStats();
    final sortedHistory = List<PriceHistoryDto>.from(priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date)); // Plus ancien en premier pour le graphique

    return CustomPaint(
      size: Size.infinite,
      painter: _PriceChartPainter(
        priceHistory: sortedHistory,
        minPrice: stats.minPrice,
        maxPrice: stats.maxPrice,
        primaryColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildChartFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Il y a ${selectedPeriodDays}j',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          'Aujourd\'hui',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  _ChartStats _calculateChartStats() {
    if (priceHistory.isEmpty) {
      return _ChartStats(minPrice: 0, maxPrice: 0, avgPrice: 0);
    }

    final prices = priceHistory.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    return _ChartStats(
      minPrice: minPrice,
      maxPrice: maxPrice,
      avgPrice: avgPrice,
    );
  }
}

class _ChartStats {
  final double minPrice;
  final double maxPrice;
  final double avgPrice;

  _ChartStats({
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
  });
}

class _PriceChartPainter extends CustomPainter {
  final List<PriceHistoryDto> priceHistory;
  final double minPrice;
  final double maxPrice;
  final Color primaryColor;

  _PriceChartPainter({
    required this.priceHistory,
    required this.minPrice,
    required this.maxPrice,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.length < 2) return;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    // Calculer les points
    for (int i = 0; i < priceHistory.length; i++) {
      final price = priceHistory[i].price;
      final x = (i / (priceHistory.length - 1)) * size.width;
      final y = size.height - ((price - minPrice) / (maxPrice - minPrice)) * size.height;
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Dessiner la ligne
    canvas.drawPath(path, paint);

    // Dessiner les points
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }

    // Dessiner la ligne de moyenne
    final avgY = size.height - (((_calculateAverage()) - minPrice) / (maxPrice - minPrice)) * size.height;
    final avgPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, avgY),
      Offset(size.width, avgY),
      avgPaint,
    );

    // Dessiner la zone sous la courbe (optionnel)
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  double _calculateAverage() {
    if (priceHistory.isEmpty) return 0;
    final sum = priceHistory.map((p) => p.price).reduce((a, b) => a + b);
    return sum / priceHistory.length;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}