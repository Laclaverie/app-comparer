import 'package:shared_models/models/price/price_historydto.dart';

class PriceFormattingHelpers {
  /// Formate un prix en euros
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(2)}€';
  }
  
  /// Formate un pourcentage 
  static String formatPercentage(double percentage) {
    return '+${percentage.toStringAsFixed(1)}%';
  }
  
  /// Formate le temps écoulé
  static String formatTimeAgo(DateTime? date) {
    if (date == null) return 'inconnu';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 1) {
      return 'il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'il y a ${difference.inDays}j';
    }
  }
  
  /// Calcule les statistiques de prix
  static PriceStatistics calculatePriceStats(List<PriceHistoryDto> prices) {
    if (prices.isEmpty) {
      return PriceStatistics(
        lowest: 0,
        highest: 0,
        average: 0,
        difference: 0,
        differencePercent: 0,
      );
    }
    
    final sortedPrices = prices.map((p) => p.price).toList()..sort();
    final lowest = sortedPrices.first;
    final highest = sortedPrices.last;
    final average = sortedPrices.reduce((a, b) => a + b) / sortedPrices.length;
    final difference = highest - lowest;
    final double differencePercent = lowest > 0 ? ((difference / lowest) * 100) : 0;
    
    return PriceStatistics(
      lowest: lowest,
      highest: highest,
      average: average,
      difference: difference,
      differencePercent: differencePercent,
    );
  }
}

/// Classe pour les statistiques de prix
class PriceStatistics {
  final double lowest;
  final double highest;
  final double average;
  final double difference;
  final double differencePercent;
  
  const PriceStatistics({
    required this.lowest,
    required this.highest,
    required this.average,
    required this.difference,
    required this.differencePercent,
  });
}