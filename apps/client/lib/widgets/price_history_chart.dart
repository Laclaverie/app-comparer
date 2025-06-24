import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'package:shared_models/models/price/price_trend.dart';
import 'package:shared_models/models/price/price_distribution.dart';
import 'shared/price_formatting_helpers.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryDto> priceHistory;
  final int selectedPeriodDays;
  final bool isAdvancedMode; // ✅ AJOUT

  const PriceHistoryChart({
    super.key,
    required this.priceHistory,
    required this.selectedPeriodDays,
    required this.isAdvancedMode, // ✅ AJOUT
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: isAdvancedMode ? 320 : 200, // ✅ Plus haut en mode avancé
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
          if (isAdvancedMode) ...[
            _buildAdvancedStats(context),
            const SizedBox(height: 8),
          ],
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
    final stats = _calculateAdvancedStats();
    
    if (!isAdvancedMode) {
      // Mode minimal - stats simples
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
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

    // Mode avancé - stats enrichies
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
            if (stats.trend != null) _buildTrendIndicator(context, stats.trend!),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Min', stats.minPrice, Colors.red)),
            Expanded(child: _buildStatCard('Moy', stats.avgPrice, Colors.blue)),
            Expanded(child: _buildStatCard('Max', stats.maxPrice, Colors.green)),
            Expanded(child: _buildVolatilityCard(stats.volatility)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    // ✅ Fonction helper pour obtenir la shade sombre
    Color getDarkShade(Color baseColor) {
      if (baseColor == Colors.red) return Colors.red.shade700;
      if (baseColor == Colors.blue) return Colors.blue.shade700;
      if (baseColor == Colors.green) return Colors.green.shade700;
      return baseColor; // Fallback
    }

    final darkColor = getDarkShade(color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: darkColor), // ✅ CORRIGÉ
          ),
          Text(
            PriceFormattingHelpers.formatPrice(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkColor, // ✅ CORRIGÉ
            ),
          ),
        ],
      ));
  }

  Widget _buildVolatilityCard(double volatility) {
    final color = _getVolatilityColor(volatility);
    final label = _getVolatilityLabel(volatility);
    
    // ✅ Fonction helper pour obtenir la shade sombre
    Color getDarkShade(Color baseColor) {
      if (baseColor == Colors.green) return Colors.green.shade700;
      if (baseColor == Colors.orange) return Colors.orange.shade700;
      if (baseColor == Colors.red) return Colors.red.shade700;
      return baseColor;
    }

    final darkColor = getDarkShade(color);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            'Volatilité',
            style: TextStyle(fontSize: 10, color: darkColor), // ✅ CORRIGÉ
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkColor, // ✅ CORRIGÉ
            ),
          ),
        ],
      ));
  }

  Widget _buildTrendIndicator(BuildContext context, PriceTrend trend) {
    IconData icon;
    Color color;
    
    switch (trend.direction) {
      case TrendDirection.increasing:
        icon = Icons.trending_up;
        color = Colors.red;
        break;
      case TrendDirection.decreasing:
        icon = Icons.trending_down;
        color = Colors.green;
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = Colors.blue;
        break;
      case TrendDirection.volatile:
        icon = Icons.show_chart;
        color = Colors.orange;
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${trend.changePercentage.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedStats(BuildContext context) {
    final stats = _calculateAdvancedStats();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (stats.distribution != null) ...[
            _buildDistributionInfo(context, stats.distribution!),
            const SizedBox(height: 8),
          ],
          if (stats.trend != null) _buildTrendInfo(context, stats.trend!),
        ],
      ),
    );
  }

  Widget _buildDistributionInfo(BuildContext context, PriceDistribution distribution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: Colors.blue[700], size: 16),
            const SizedBox(width: 6),
            Text(
              'Distribution des prix',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildQuartileInfo('Q1', distribution.quartiles[0]),
            ),
            Expanded(
              child: _buildQuartileInfo('Médiane', distribution.median),
            ),
            Expanded(
              child: _buildQuartileInfo('Q3', distribution.quartiles[2]),
            ),
            Expanded(
              child: _buildQuartileInfo('IQR', distribution.interquartileRange),
            ),
          ],
        ),
        if (distribution.hasOutliers) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600], size: 12),
              const SizedBox(width: 4),
              Text(
                '${distribution.outliers.length} prix aberrants détectés',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuartileInfo(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.blue[600]),
        ),
        Text(
          PriceFormattingHelpers.formatPrice(value),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendInfo(BuildContext context, PriceTrend trend) {
    return Row(
      children: [
        Icon(Icons.timeline, color: Colors.blue[700], size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            trend.description,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          'Force: ${trend.trendStrength.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.blue[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 0.1) return Colors.green;
    if (volatility < 0.3) return Colors.orange;
    return Colors.red;
  }

  String _getVolatilityLabel(double volatility) {
    if (volatility < 0.1) return 'Stable';
    if (volatility < 0.3) return 'Modérée';
    return 'Élevée';
  }

  _AdvancedChartStats _calculateAdvancedStats() {
    if (priceHistory.isEmpty) {
      return _AdvancedChartStats(
        minPrice: 0,
        maxPrice: 0,
        avgPrice: 0,
        volatility: 0,
        movingAverage: [],
      );
    }

    final prices = priceHistory.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    // Calculer volatilité
    final variance = prices.map((p) => (p - avgPrice) * (p - avgPrice)).reduce((a, b) => a + b) / prices.length;
    final volatility = Math.sqrt(variance) / avgPrice;

    // Moyennes mobiles (7 jours)
    final movingAverage = _calculateMovingAverage(prices, 7);

    if (!isAdvancedMode) {
      return _AdvancedChartStats(
        minPrice: minPrice,
        maxPrice: maxPrice,
        avgPrice: avgPrice,
        volatility: volatility,
        movingAverage: movingAverage,
      );
    }

    // Mode avancé - calculer trend et distribution
    final trend = _calculatePriceTrend(priceHistory);
    final distribution = _calculatePriceDistribution(prices);

    return _AdvancedChartStats(
      minPrice: minPrice,
      maxPrice: maxPrice,
      avgPrice: avgPrice,
      trend: trend,
      distribution: distribution,
      volatility: volatility,
      movingAverage: movingAverage,
    );
  }

  PriceTrend? _calculatePriceTrend(List<PriceHistoryDto> history) {
    if (history.length < 2) return null;

    final sortedHistory = List<PriceHistoryDto>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    final startPrice = sortedHistory.first.price;
    final endPrice = sortedHistory.last.price;
    final changeAmount = endPrice - startPrice;
    final changePercentage = (changeAmount / startPrice) * 100;

    // Déterminer direction
    TrendDirection direction;
    if (changePercentage.abs() < 2) {
      direction = TrendDirection.stable;
    } else if (changePercentage > 0) {
      direction = TrendDirection.increasing;
    } else {
      direction = TrendDirection.decreasing;
    }

    // Calculer force de la tendance (coefficient de corrélation simplifié)
    final prices = sortedHistory.map((p) => p.price).toList();
    final trendStrength = _calculateTrendStrength(prices);

    return PriceTrend(
      direction: direction,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
      startDate: sortedHistory.first.date,
      endDate: sortedHistory.last.date,
      historicalPrices: prices,
      trendStrength: trendStrength,
    );
  }

  PriceDistribution? _calculatePriceDistribution(List<double> prices) {
    if (prices.length < 4) return null;

    final sortedPrices = List<double>.from(prices)..sort();
    final n = sortedPrices.length;

    // Calculer quartiles
    final q1 = sortedPrices[(n * 0.25).floor()];
    final median = sortedPrices[(n * 0.5).floor()];
    final q3 = sortedPrices[(n * 0.75).floor()];
    final quartiles = [q1, median, q3];

    // Détecter outliers (méthode IQR)
    final iqr = q3 - q1;
    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;
    final outliers = sortedPrices.where((p) => p < lowerBound || p > upperBound).toList();

    // Créer ranges de prix
    final priceRanges = _createPriceRanges(sortedPrices);

    return PriceDistribution(
      quartiles: quartiles,
      outliers: outliers,
      priceRanges: priceRanges,
    );
  }

  List<PriceRange> _createPriceRanges(List<double> sortedPrices) {
    final minPrice = sortedPrices.first;
    final maxPrice = sortedPrices.last;
    final rangeWidth = (maxPrice - minPrice) / 4; // 4 ranges

    final List<PriceRange> ranges = [];
    
    for (int i = 0; i < 4; i++) {
      final min = minPrice + (i * rangeWidth);
      final max = i == 3 ? maxPrice : min + rangeWidth;
      
      final count = sortedPrices.where((p) => p >= min && p <= max).length;
      final percentage = (count / sortedPrices.length) * 100;
      
      if (count > 0) {
        ranges.add(PriceRange(
          min: min,
          max: max,
          count: count,
          percentage: percentage,
        ));
      }
    }
    
    return ranges;
  }

  double _calculateTrendStrength(List<double> prices) {
    if (prices.length < 2) return 0;
    
    // Corrélation linéaire simple
    final n = prices.length;
    final indices = List.generate(n, (i) => i.toDouble());
    
    final meanX = indices.reduce((a, b) => a + b) / n;
    final meanY = prices.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double denomX = 0;
    double denomY = 0;
    
    for (int i = 0; i < n; i++) {
      final diffX = indices[i] - meanX;
      final diffY = prices[i] - meanY;
      numerator += diffX * diffY;
      denomX += diffX * diffX;
      denomY += diffY * diffY;
    }
    
    final correlation = numerator / Math.sqrt(denomX * denomY);
    return correlation.abs();
  }

  List<double> _calculateMovingAverage(List<double> prices, int window) {
    if (prices.length < window) return [];
    
    final movingAvg = <double>[];
    for (int i = window - 1; i < prices.length; i++) {
      final sum = prices.sublist(i - window + 1, i + 1).reduce((a, b) => a + b);
      movingAvg.add(sum / window);
    }
    return movingAvg;
  }

  Widget _buildChart(BuildContext context) {
    final stats = _calculateAdvancedStats();
    final sortedHistory = List<PriceHistoryDto>.from(priceHistory)
      ..sort((a, b) => a.date.compareTo(b.date)); // Plus ancien en premier pour le graphique

    return CustomPaint(
      size: Size.infinite,
      painter: _PriceChartPainter(
        priceHistory: sortedHistory,
        minPrice: stats.minPrice,
        maxPrice: stats.maxPrice,
        primaryColor: Theme.of(context).primaryColor,
        isAdvancedMode: isAdvancedMode,
        movingAverage: stats.movingAverage,
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
            color: Colors.grey.shade600,
          ),
        ),
        if (isAdvancedMode && priceHistory.isNotEmpty) ...[
          Text(
            '${priceHistory.length} points de données',
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

class _AdvancedChartStats {
  // Stats basiques (mode minimal)
  final double minPrice;
  final double maxPrice;
  final double avgPrice;
  
  // Stats avancées (mode avancé)
  final PriceTrend? trend;
  final PriceDistribution? distribution;
  final double volatility;
  final List<double> movingAverage;
  
  _AdvancedChartStats({
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
    this.trend,
    this.distribution,
    required this.volatility,
    required this.movingAverage,
  });
}

class _PriceChartPainter extends CustomPainter {
  final List<PriceHistoryDto> priceHistory;
  final double minPrice;
  final double maxPrice;
  final Color primaryColor;
  final bool isAdvancedMode;
  final List<double> movingAverage;

  _PriceChartPainter({
    required this.priceHistory,
    required this.minPrice,
    required this.maxPrice,
    required this.primaryColor,
    required this.isAdvancedMode,
    required this.movingAverage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.length < 2) return;

    // 1. Dessiner la zone sous la courbe (arrière-plan)
    _drawFillArea(canvas, size);

    // 2. Dessiner la ligne de moyenne (mode avancé)
    if (isAdvancedMode) {
      _drawAverageLine(canvas, size);
    }

    // 3. Dessiner la moyenne mobile (mode avancé)
    if (isAdvancedMode && movingAverage.isNotEmpty) {
      _drawMovingAverage(canvas, size);
    }

    // 4. Dessiner la ligne principale des prix
    _drawPriceLine(canvas, size);

    // 5. Dessiner les points de données
    _drawDataPoints(canvas, size);

    // 6. Dessiner les outliers (mode avancé)
    if (isAdvancedMode) {
      _drawOutliers(canvas, size);
    }
  }

  void _drawFillArea(Canvas canvas, Size size) {
    final path = _createPricePath(size);
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawAverageLine(Canvas canvas, Size size) {
    final avgPrice = _calculateAverage();
    final avgY = size.height - ((avgPrice - minPrice) / (maxPrice - minPrice)) * size.height;
    
    final avgPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Ligne pointillée pour la moyenne
    _drawDashedLine(canvas, Offset(0, avgY), Offset(size.width, avgY), avgPaint);
  }

  void _drawMovingAverage(Canvas canvas, Size size) {
    if (movingAverage.length < 2) return;

    final movingPath = Path();
    final startIndex = priceHistory.length - movingAverage.length;

    for (int i = 0; i < movingAverage.length; i++) {
      final actualIndex = startIndex + i;
      final x = (actualIndex / (priceHistory.length - 1)) * size.width;
      final y = size.height - ((movingAverage[i] - minPrice) / (maxPrice - minPrice)) * size.height;
      
      if (i == 0) {
        movingPath.moveTo(x, y);
      } else {
        movingPath.lineTo(x, y);
      }
    }

    final movingPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(movingPath, movingPaint);
  }

  void _drawPriceLine(Canvas canvas, Size size) {
    final path = _createPricePath(size);
    
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = isAdvancedMode ? 2.5 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  void _drawDataPoints(Canvas canvas, Size size) {
    final points = _calculatePoints(size);
    
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isRecent = i >= points.length - 3; // 3 derniers points
      final radius = isAdvancedMode && isRecent ? 4.0 : 3.0;
      
      // Bordure blanche
      canvas.drawCircle(point, radius + 1, borderPaint);
      // Point principal
      canvas.drawCircle(point, radius, pointPaint);
    }
  }

  void _drawOutliers(Canvas canvas, Size size) {
    // Détecter et marquer les outliers
    final prices = priceHistory.map((p) => p.price).toList();
    final sortedPrices = List<double>.from(prices)..sort();
    final n = sortedPrices.length;
    
    if (n < 4) return;
    
    final q1 = sortedPrices[(n * 0.25).floor()];
    final q3 = sortedPrices[(n * 0.75).floor()];
    final iqr = q3 - q1;
    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;
    
    final points = _calculatePoints(size);
    final outlierPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < priceHistory.length; i++) {
      final price = priceHistory[i].price;
      if (price < lowerBound || price > upperBound) {
        // Dessiner un cercle rouge autour des outliers
        canvas.drawCircle(points[i], 6, outlierPaint);
      }
    }
  }

  Path _createPricePath(Size size) {
    final path = Path();
    final points = _calculatePoints(size);
    
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    
    return path;
  }

  List<Offset> _calculatePoints(Size size) {
    final points = <Offset>[];
    
    for (int i = 0; i < priceHistory.length; i++) {
      final price = priceHistory[i].price;
      final x = (i / (priceHistory.length - 1)) * size.width;
      final y = size.height - ((price - minPrice) / (maxPrice - minPrice)) * size.height;
      points.add(Offset(x, y));
    }
    
    return points;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 5.0;
    const gapLength = 3.0;
    
    final distance = (end - start).distance;
    final dashCount = (distance / (dashLength + gapLength)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startRatio = (i * (dashLength + gapLength)) / distance;
      final endRatio = ((i * (dashLength + gapLength)) + dashLength) / distance;
      
      final dashStart = Offset.lerp(start, end, startRatio)!;
      final dashEnd = Offset.lerp(start, end, endRatio)!;
      
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  double _calculateAverage() {
    if (priceHistory.isEmpty) return 0;
    final sum = priceHistory.map((p) => p.price).reduce((a, b) => a + b);
    return sum / priceHistory.length;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}