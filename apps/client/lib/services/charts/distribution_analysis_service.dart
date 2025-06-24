import 'package:shared_models/models/price/price_historydto.dart';
import 'package:shared_models/models/price/price_distribution.dart';

class DistributionAnalysisService {
  /// Calcule la distribution des prix
  static PriceDistribution? calculateDistribution(List<PriceHistoryDto> priceHistory) {
    if (priceHistory.length < 4) return null;

    final prices = priceHistory.map((p) => p.price).toList();
    final sortedPrices = List<double>.from(prices)..sort();
    
    final quartiles = _calculateQuartiles(sortedPrices);
    final outliers = _detectOutliers(sortedPrices, quartiles);
    final priceRanges = _createPriceRanges(sortedPrices);

    return PriceDistribution(
      quartiles: quartiles,
      outliers: outliers,
      priceRanges: priceRanges,
    );
  }

  static List<double> _calculateQuartiles(List<double> sortedPrices) {
    final n = sortedPrices.length;
    final q1 = sortedPrices[(n * 0.25).floor()];
    final median = sortedPrices[(n * 0.5).floor()];
    final q3 = sortedPrices[(n * 0.75).floor()];
    return [q1, median, q3];
  }

  static List<double> _detectOutliers(List<double> sortedPrices, List<double> quartiles) {
    final q1 = quartiles[0];
    final q3 = quartiles[2];
    final iqr = q3 - q1;
    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;
    
    return sortedPrices.where((p) => p < lowerBound || p > upperBound).toList();
  }

  static List<PriceRange> _createPriceRanges(List<double> sortedPrices) {
    final minPrice = sortedPrices.first;
    final maxPrice = sortedPrices.last;
    final rangeWidth = (maxPrice - minPrice) / 4;

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
}