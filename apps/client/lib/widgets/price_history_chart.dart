import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import '../services/charts/price_chart_data_service.dart';
import '../services/charts/price_statistics_service.dart';
import 'shared/price_formatting_helpers.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryDto> priceHistory;
  final int selectedPeriodDays;
  final bool isAdvancedMode;

  const PriceHistoryChart({
    super.key,
    required this.priceHistory,
    required this.selectedPeriodDays,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return _buildEmptyChart(context);
    }

    // ✅ Service fait tous les calculs
    final chartData = PriceChartDataService.prepareChartData(priceHistory, isAdvancedMode);

    return Container(
      height: isAdvancedMode ? 320 : 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _PriceChartHeader(chartData: chartData, isAdvancedMode: isAdvancedMode),
          const SizedBox(height: 16),
          Expanded(child: _PriceChartCanvas(chartData: chartData, isAdvancedMode: isAdvancedMode)),
          const SizedBox(height: 8),
          if (isAdvancedMode) ...[
            _PriceChartAdvancedStats(chartData: chartData),
            const SizedBox(height: 8),
          ],
          _PriceChartFooter(selectedPeriodDays: selectedPeriodDays, dataPointsCount: chartData.sortedHistory.length, isAdvancedMode: isAdvancedMode),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Pas assez de données',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Composants séparés pour chaque partie
class _PriceChartHeader extends StatelessWidget {
  final PriceChartData chartData;
  final bool isAdvancedMode;

  const _PriceChartHeader({
    required this.chartData,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    final stats = chartData.stats.basicStats;
    
    if (!isAdvancedMode) {
      return _buildSimpleHeader(stats);
    }
    
    return _buildAdvancedHeader(context, chartData);
  }

  Widget _buildSimpleHeader(BasicPriceStats stats) {
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
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Max: ${PriceFormattingHelpers.formatPrice(stats.maxPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
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
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              PriceFormattingHelpers.formatPrice(stats.avgPrice),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedHeader(BuildContext context, PriceChartData chartData) {
    // Implementation avancée...
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Analyse avancée',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Trend indicator si disponible
          ],
        ),
        const SizedBox(height: 12),
        // Stats cards...
      ],
    );
  }
}

class _PriceChartCanvas extends StatelessWidget {
  final PriceChartData chartData;
  final bool isAdvancedMode;

  const _PriceChartCanvas({
    required this.chartData,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SimplePriceChartPainter(
        chartData: chartData,
        primaryColor: Theme.of(context).primaryColor,
        isAdvancedMode: isAdvancedMode,
      ),
    );
  }
}

class _PriceChartFooter extends StatelessWidget {
  final int selectedPeriodDays;
  final int dataPointsCount;
  final bool isAdvancedMode;

  const _PriceChartFooter({
    required this.selectedPeriodDays,
    required this.dataPointsCount,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Il y a ${selectedPeriodDays}j',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        if (isAdvancedMode && dataPointsCount > 0) ...[
          Text(
            '$dataPointsCount points de données',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        Text(
          'Aujourd\'hui',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _PriceChartAdvancedStats extends StatelessWidget {
  final PriceChartData chartData;

  const _PriceChartAdvancedStats({required this.chartData});

  @override
  Widget build(BuildContext context) {
    // Stats avancées pour mode avancé
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Distribution, tendance, etc.
        ],
      ),
    );
  }
}

// ✅ Painter simplifié - reçoit des données pré-calculées
class _SimplePriceChartPainter extends CustomPainter {
  final PriceChartData chartData;
  final Color primaryColor;
  final bool isAdvancedMode;

  _SimplePriceChartPainter({
    required this.chartData,
    required this.primaryColor,
    required this.isAdvancedMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.isEmpty) return;

    // Convertir les points normalisés en pixels
    final pixelPoints = chartData.chartPoints.map((point) {
      return Offset(point.dx * size.width, point.dy * size.height);
    }).toList();

    _drawChart(canvas, size, pixelPoints);
  }

  void _drawChart(Canvas canvas, Size size, List<Offset> points) {
    // 1. Zone sous la courbe
    _drawFillArea(canvas, size, points);
    
    // 2. Ligne principale
    _drawMainLine(canvas, points);
    
    // 3. Points de données
    _drawDataPoints(canvas, points);
    
    // 4. Mode avancé : outliers, moyennes mobiles, etc.
    if (isAdvancedMode) {
      _drawAdvancedElements(canvas, size, points);
    }
  }

  void _drawFillArea(Canvas canvas, Size size, List<Offset> points) {
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  void _drawMainLine(Canvas canvas, List<Offset> points) {
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = isAdvancedMode ? 2.5 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  void _drawDataPoints(Canvas canvas, List<Offset> points) {
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isRecent = i >= points.length - 3;
      final radius = isAdvancedMode && isRecent ? 4.0 : 3.0;
      
      canvas.drawCircle(point, radius + 1, borderPaint);
      canvas.drawCircle(point, radius, pointPaint);
    }
  }

  void _drawAdvancedElements(Canvas canvas, Size size, List<Offset> points) {
    // Outliers
    final outlierPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final index in chartData.outlierIndices) {
      if (index < points.length) {
        canvas.drawCircle(points[index], 6, outlierPaint);
      }
    }

    // Ligne de moyenne
    final avgY = chartData.stats.basicStats.avgPrice;
    final normalizedAvgY = 1 - ((avgY - chartData.stats.basicStats.minPrice) / 
        (chartData.stats.basicStats.maxPrice - chartData.stats.basicStats.minPrice));
    final avgYPixel = normalizedAvgY * size.height;
    
    final avgPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, avgYPixel),
      Offset(size.width, avgYPixel),
      avgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}