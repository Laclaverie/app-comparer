/// Represents the statistical distribution of prices across different stores
/// Provides quartile analysis, outlier detection, and price range grouping
class PriceDistribution {
  final List<double> quartiles;
  final List<double> outliers;
  final List<PriceRange> priceRanges;

  PriceDistribution({
    required this.quartiles,
    required this.outliers,
    required this.priceRanges,
  });
}

/// Represents a specific price range with its frequency distribution
/// Used to analyze how prices are clustered across different price bands
/// Helpful for market analysis and identifying pricing patterns
class PriceRange {
  final double min;
  final double max;
  final int count;
  final double percentage;

  PriceRange({
    required this.min,
    required this.max,
    required this.count,
    required this.percentage,
  });
}