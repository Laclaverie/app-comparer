import 'dart:math';
import 'package:shared_models/models/product/product_statistics.dart';
import 'package:shared_models/models/store/store_price.dart';
import 'package:shared_models/models/price/price_trend.dart';
import 'package:shared_models/models/price/price_distribution.dart';
import 'package:shared_models/models/store/store_comparison.dart';
import 'price_calculator.dart';

/// Provides comprehensive statistical analysis and calculations for product pricing data
/// Handles price distribution analysis, trend calculations, and store comparisons
/// Used to generate insights and help users make informed purchasing decisions
class ProductStatisticsService {
  /// Calculate comprehensive statistics for a list of store prices
  static ProductStatistics calculateStatistics(List<StorePrice> storePrices) {
    if (storePrices.isEmpty) {
      throw ArgumentError('Cannot calculate statistics for empty price list');
    }

    // Get effective prices considering promotions
    final effectivePrices = storePrices
        .map((store) => PriceCalculator.getEffectivePrice(store))
        .toList();

    // Sort prices for median calculation
    final sortedPrices = List<double>.from(effectivePrices)..sort();

    // Find best and worst deals
    final bestDeal = _findBestDeal(storePrices);
    final worstDeal = _findWorstDeal(storePrices);

    return ProductStatistics(
      averagePrice: _calculateAverage(effectivePrices),
      medianPrice: _calculateMedian(sortedPrices),
      minPrice: sortedPrices.first,
      maxPrice: sortedPrices.last,
      priceVariance: _calculateVariance(effectivePrices),
      standardDeviation: _calculateStandardDeviation(effectivePrices),
      bestDeal: bestDeal,
      worstDeal: worstDeal,
      allPrices: List.unmodifiable(storePrices),
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate price trend over time periods
  static PriceTrend calculateTrend(List<StorePrice> historicalPrices) {
    // Group prices by time periods (daily, weekly, monthly)
    // Calculate trend direction and magnitude
    // Implementation depends on your historical data structure
    throw UnimplementedError('Price trend calculation to be implemented');
  }

  /// Calculate price distribution analysis
  static PriceDistribution analyzeDistribution(List<StorePrice> storePrices) {
    final effectivePrices = storePrices
        .map((store) => PriceCalculator.getEffectivePrice(store))
        .toList();

    return PriceDistribution(
      quartiles: _calculateQuartiles(effectivePrices),
      outliers: _findOutliers(effectivePrices),
      priceRanges: _createPriceRanges(effectivePrices),
    );
  }

  /// Calculate store comparison metrics
  static List<StoreComparison> compareStores(List<StorePrice> storePrices) {
    final avgPrice = _calculateAverage(
      storePrices.map((s) => PriceCalculator.getEffectivePrice(s)).toList()
    );

    return storePrices.map((store) {
      final effectivePrice = PriceCalculator.getEffectivePrice(store);
      return StoreComparison(
        storeName: store.storeName,
        effectivePrice: effectivePrice,
        savingsFromAverage: avgPrice - effectivePrice,
        savingsPercentage: ((avgPrice - effectivePrice) / avgPrice) * 100,
        rank: 0, // Will be set after sorting
      );
    }).toList()
      ..sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice))
      ..asMap().forEach((index, store) => store.rank = index + 1);
  }

  // Private helper methods
  static double _calculateAverage(List<double> prices) {
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  static double _calculateMedian(List<double> sortedPrices) {
    final length = sortedPrices.length;
    if (length % 2 == 0) {
      return (sortedPrices[length ~/ 2 - 1] + sortedPrices[length ~/ 2]) / 2;
    } else {
      return sortedPrices[length ~/ 2];
    }
  }

  static double _calculateVariance(List<double> prices) {
    final mean = _calculateAverage(prices);
    final squaredDiffs = prices.map((price) => pow(price - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / prices.length;
  }

  static double _calculateStandardDeviation(List<double> prices) {
    return sqrt(_calculateVariance(prices));
  }

  static StorePrice _findBestDeal(List<StorePrice> storePrices) {
    return storePrices.reduce((best, current) {
      final bestPrice = PriceCalculator.getEffectivePrice(best);
      final currentPrice = PriceCalculator.getEffectivePrice(current);
      return currentPrice < bestPrice ? current : best;
    });
  }

  static StorePrice _findWorstDeal(List<StorePrice> storePrices) {
    return storePrices.reduce((worst, current) {
      final worstPrice = PriceCalculator.getEffectivePrice(worst);
      final currentPrice = PriceCalculator.getEffectivePrice(current);
      return currentPrice > worstPrice ? current : worst;
    });
  }

  static List<double> _calculateQuartiles(List<double> prices) {
    final sorted = List<double>.from(prices)..sort();
    final length = sorted.length;
    
    return [
      sorted[(length * 0.25).floor()],  // Q1
      _calculateMedian(sorted),         // Q2 (median)
      sorted[(length * 0.75).floor()],  // Q3
    ];
  }

  static List<double> _findOutliers(List<double> prices) {
    final quartiles = _calculateQuartiles(prices);
    final iqr = quartiles[2] - quartiles[0]; // Q3 - Q1
    final lowerBound = quartiles[0] - (1.5 * iqr);
    final upperBound = quartiles[2] + (1.5 * iqr);
    
    return prices.where((price) => price < lowerBound || price > upperBound).toList();
  }

  static List<PriceRange> _createPriceRanges(List<double> prices) {
    if (prices.isEmpty) return [];
    
    final sorted = List<double>.from(prices)..sort();
    final min = sorted.first;
    final max = sorted.last;
    final range = max - min;
    
    // Create 5 equal ranges
    const rangeCount = 5;
    final rangeSize = range / rangeCount;
    
    final ranges = <PriceRange>[];
    
    for (int i = 0; i < rangeCount; i++) {
      final rangeMin = min + (i * rangeSize);
      final rangeMax = i == rangeCount - 1 ? max : min + ((i + 1) * rangeSize);
      
      final count = prices.where((price) => 
        price >= rangeMin && (i == rangeCount - 1 ? price <= rangeMax : price < rangeMax)
      ).length;
      
      final percentage = (count / prices.length) * 100;
      
      ranges.add(PriceRange(
        min: rangeMin,
        max: rangeMax,
        count: count,
        percentage: percentage,
      ));
    }
    
    return ranges;
  }
}