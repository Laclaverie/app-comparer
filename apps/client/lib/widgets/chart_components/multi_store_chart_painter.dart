import 'package:flutter/material.dart';
import '../../services/charts/store_comparison_service.dart';
import '../../services/charts/price_statistics_service.dart';

class MultiStoreChartPainter extends CustomPainter {
  final Map<int, StoreChartData> storeData;
  final Map<int, List<Offset>> storePoints;
  final BasicPriceStats globalStats;
  final bool isAdvancedMode;

  MultiStoreChartPainter({
    required this.storeData,
    required this.storePoints,
    required this.globalStats,
    required this.isAdvancedMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (storeData.isEmpty) return;

    final chartRect = Rect.fromLTWH(
      60,
      20,
      size.width - 80,
      size.height - 50,
    );

    _drawFillAreas(canvas, chartRect);
    _drawStoreLines(canvas, chartRect);
    _drawDataPoints(canvas, chartRect);
    
    // ✅ Désactiver temporairement la légende inline qui cause l'overflow
    // if (isAdvancedMode) {
    //   _drawInlineLegend(canvas, chartRect, size);
    // }
  }

  void _drawFillAreas(Canvas canvas, Rect chartRect) {
    storeData.forEach((storeId, data) {
      if (!data.isVisible || !storePoints.containsKey(storeId)) return;
      
      final points = storePoints[storeId]!;
      if (points.length < 2) return;
      
      // ✅ CORRIGÉ : Ajouter chartRect.left et chartRect.top
      final pixelPoints = points.map((point) {
        return Offset(
          chartRect.left + (point.dx * chartRect.width),
          chartRect.top + (point.dy * chartRect.height),
        );
      }).toList();
      
      final path = Path();
      for (int i = 0; i < pixelPoints.length; i++) {
        if (i == 0) {
          path.moveTo(pixelPoints[i].dx, pixelPoints[i].dy);
        } else {
          path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
        }
      }
      
      // Fermer la zone
      path.lineTo(chartRect.right, chartRect.bottom);
      path.lineTo(chartRect.left, chartRect.bottom);
      path.close();

      final fillPaint = Paint()
        ..color = data.color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    });
  }

  void _drawStoreLines(Canvas canvas, Rect chartRect) {
    storeData.forEach((storeId, data) {
      if (!data.isVisible || !storePoints.containsKey(storeId)) return;
      
      final points = storePoints[storeId]!;
      if (points.length < 2) return;
      
      final pixelPoints = points.map((point) {
        return Offset(
          chartRect.left + (point.dx * chartRect.width),
          chartRect.top + (point.dy * chartRect.height),
        );
      }).toList();
      
      final path = Path();
      for (int i = 0; i < pixelPoints.length; i++) {
        if (i == 0) {
          path.moveTo(pixelPoints[i].dx, pixelPoints[i].dy);
        } else {
          path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
        }
      }

      // ✅ Lignes plus épaisses pour la grande taille
      final paint = Paint()
        ..color = data.color
        ..strokeWidth = isAdvancedMode ? 3.5 : 3.0 // +1px
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);
    });
  }

  void _drawDataPoints(Canvas canvas, Rect chartRect) {
    storeData.forEach((storeId, data) {
      if (!data.isVisible || !storePoints.containsKey(storeId)) return;
      
      final points = storePoints[storeId]!;
      final pixelPoints = points.map((point) {
        return Offset(
          chartRect.left + (point.dx * chartRect.width),
          chartRect.top + (point.dy * chartRect.height),
        );
      }).toList();
      
      final pointPaint = Paint()
        ..color = data.color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (int i = 0; i < pixelPoints.length; i++) {
        final point = pixelPoints[i];
        final isRecent = i >= pixelPoints.length - 3;
        // ✅ Points plus gros pour la grande taille
        final radius = isAdvancedMode && isRecent ? 6.0 : 5.0;
        
        canvas.drawCircle(point, radius + 1.5, borderPaint);
        canvas.drawCircle(point, radius, pointPaint);
      }
    });
  }

  void _drawInlineLegend(Canvas canvas, Rect chartRect, Size size) {
    final visibleStores = storeData.values.where((s) => s.isVisible).toList();
    
    for (int i = 0; i < visibleStores.length; i++) {
      final store = visibleStores[i];
      if (store.prices.isEmpty) continue;
      
      final lastPrice = store.prices.last.price;
      final normalizedY = 1 - ((lastPrice - globalStats.minPrice) / (globalStats.maxPrice - globalStats.minPrice));
      final y = chartRect.top + (normalizedY * chartRect.height);
      
      final endPoint = Offset(chartRect.right, y);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${store.storeName}: ${lastPrice.toStringAsFixed(2)}€',
          style: TextStyle(
            color: store.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            backgroundColor: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final labelX = chartRect.right + 12;
      final labelY = y - (textPainter.height / 2);
      
      if (labelX + textPainter.width <= size.width - 12) {
        // Fond blanc pour meilleure lisibilité
        final backgroundRect = Rect.fromLTWH(
          labelX - 4,
          labelY - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        );
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
        
        textPainter.paint(canvas, Offset(labelX, labelY));
        
        // Ligne de connexion
        final connectionPaint = Paint()
          ..color = store.color.withValues(alpha: 0.7)
          ..strokeWidth = 2.0;
        
        canvas.drawLine(
          endPoint,
          Offset(labelX - 6, y),
          connectionPaint,
        );
      } else {
        // Fallback : Label plus court
        final shortText = '${lastPrice.toStringAsFixed(2)}€';
        final shortTextPainter = TextPainter(
          text: TextSpan(
            text: shortText,
            style: TextStyle(
              color: store.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        shortTextPainter.layout();
        
        if (labelX + shortTextPainter.width <= size.width - 8) {
          final backgroundRect = Rect.fromLTWH(
            labelX - 4,
            labelY - 2,
            shortTextPainter.width + 8,
            shortTextPainter.height + 4,
          );
          
          canvas.drawRRect(
            RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
            Paint()..color = Colors.white.withValues(alpha: 0.95),
          );
          
          shortTextPainter.paint(canvas, Offset(labelX, labelY));
          
          final connectionPaint = Paint()
            ..color = store.color.withValues(alpha: 0.7)
            ..strokeWidth = 2.0;
          
          canvas.drawLine(
            endPoint,
            Offset(labelX - 6, y),
            connectionPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}