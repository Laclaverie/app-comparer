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