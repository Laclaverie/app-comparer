// lib/widgets/chart_components/price_chart_axes.dart
import 'package:flutter/material.dart';
import '../../services/charts/price_statistics_service.dart';
import '../shared/price_formatting_helpers.dart';

class PriceChartAxes extends StatelessWidget {
  final BasicPriceStats stats;
  final int selectedPeriodDays;
  final Size chartSize;
  final bool isAdvancedMode;

  const PriceChartAxes({
    super.key,
    required this.stats,
    required this.selectedPeriodDays,
    required this.chartSize,
    required this.isAdvancedMode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: chartSize,
      painter: _AxesPainter(
        stats: stats,
        selectedPeriodDays: selectedPeriodDays,
        isAdvancedMode: isAdvancedMode,
      ),
    );
  }
}

class _AxesPainter extends CustomPainter {
  final BasicPriceStats stats;
  final int selectedPeriodDays;
  final bool isAdvancedMode;

  _AxesPainter({
    required this.stats,
    required this.selectedPeriodDays,
    required this.isAdvancedMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      60,
      20,
      size.width - 80,
      size.height - 50,
    );
    
    _drawYAxis(canvas, chartRect);
    _drawXAxis(canvas, chartRect);
    if (isAdvancedMode) {
      _drawGridLines(canvas, chartRect);
    }
  }

  void _drawYAxis(Canvas canvas, Rect chartRect) {
    final axisColor = Colors.grey.shade400;
    final textColor = Colors.grey.shade600;
    
    // ✅ Ligne de l'axe Y plus visible
    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      Paint()..color = axisColor..strokeWidth = 1.5, // Plus épaisse
    );

    // ✅ Plus de niveaux de prix pour la grande taille
    final levels = isAdvancedMode ? 6 : 4; // Plus de détails en mode avancé
    final priceRange = stats.maxPrice - stats.minPrice;
    final stepSize = priceRange / levels;
    
    for (int i = 0; i <= levels; i++) {
      final price = stats.minPrice + (stepSize * i);
      final y = chartRect.bottom - ((i / levels) * chartRect.height);
      
      // Grille horizontale
      if (isAdvancedMode) {
        canvas.drawLine(
          Offset(chartRect.left, y),
          Offset(chartRect.right, y),
          Paint()..color = Colors.grey.shade200..strokeWidth = 0.8,
        );
      }
      
      // ✅ Labels de prix plus grands
      final textPainter = TextPainter(
        text: TextSpan(
          text: PriceFormattingHelpers.formatPrice(price),
          style: TextStyle(
            color: textColor,
            fontSize: 12, // ✅ Plus grand (était 10)
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartRect.left - textPainter.width - 12, y - (textPainter.height / 2)), // Plus d'espace
      );
    }
  }

  void _drawXAxis(Canvas canvas, Rect chartRect) {
    final axisColor = Colors.grey.shade400;
    final textColor = Colors.grey.shade600;
    
    // ✅ Ligne de l'axe X plus visible
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      Paint()..color = axisColor..strokeWidth = 1.5,
    );

    final timeLabels = _generateTimeLabels();
    
    for (int i = 0; i < timeLabels.length; i++) {
      final x = chartRect.left + (i / (timeLabels.length - 1)) * chartRect.width;
      
      if (isAdvancedMode && i > 0 && i < timeLabels.length - 1) {
        canvas.drawLine(
          Offset(x, chartRect.top),
          Offset(x, chartRect.bottom),
          Paint()..color = Colors.grey.shade200..strokeWidth = 0.8,
        );
      }
      
      // ✅ Labels temporels plus grands
      final textPainter = TextPainter(
        text: TextSpan(
          text: timeLabels[i],
          style: TextStyle(
            color: textColor,
            fontSize: 12, // ✅ Plus grand
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), chartRect.bottom + 8), // Plus d'espace
      );
    }
  }
  
  void _drawGridLines(Canvas canvas, Rect chartRect) {
    // Déjà dessinées dans _drawYAxis et _drawXAxis
  }

  List<String> _generateTimeLabels() {
    if (selectedPeriodDays <= 7) {
      return ['7j', '6j', '5j', '4j', '3j', '2j', '1j', 'Auj'];
    } else if (selectedPeriodDays <= 30) {
      return ['${selectedPeriodDays}j', '${(selectedPeriodDays * 0.75).round()}j', 
              '${(selectedPeriodDays * 0.5).round()}j', '${(selectedPeriodDays * 0.25).round()}j', 'Aujourd\'hui'];
    } else {
      // Pour les périodes longues, utiliser des semaines
      return ['${(selectedPeriodDays / 7).round()}sem', 
              '${(selectedPeriodDays / 7 * 0.75).round()}sem',
              '${(selectedPeriodDays / 7 * 0.5).round()}sem', 
              '${(selectedPeriodDays / 7 * 0.25).round()}sem', 
              'Auj'];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}