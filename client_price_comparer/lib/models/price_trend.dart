enum TrendDirection {
  increasing,
  decreasing,
  stable,
  volatile,
}

class PriceTrend {
  final TrendDirection direction;
  final double changeAmount;
  final double changePercentage;
  final DateTime startDate;
  final DateTime endDate;
  final List<double> historicalPrices;
  final double trendStrength; // 0.0 to 1.0, how strong the trend is

  PriceTrend({
    required this.direction,
    required this.changeAmount,
    required this.changePercentage,
    required this.startDate,
    required this.endDate,
    required this.historicalPrices,
    required this.trendStrength,
  });

  /// Get trend description for UI display
  String get description {
    switch (direction) {
      case TrendDirection.increasing:
        return 'Price increasing by ${changePercentage.toStringAsFixed(1)}%';
      case TrendDirection.decreasing:
        return 'Price decreasing by ${changePercentage.abs().toStringAsFixed(1)}%';
      case TrendDirection.stable:
        return 'Price stable (±${changePercentage.abs().toStringAsFixed(1)}%)';
      case TrendDirection.volatile:
        return 'Price volatile with ${trendStrength.toStringAsFixed(1)} volatility';
    }
  }

  /// Check if trend is significant (beyond noise threshold)
  bool get isSignificant => trendStrength > 0.3;

  /// Get trend duration in days
  int get durationInDays => endDate.difference(startDate).inDays;
}