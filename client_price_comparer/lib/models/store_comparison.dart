/// Represents a comparison analysis between a store's price and market averages
/// Provides ranking, savings calculations, and formatted descriptions for UI display
/// Used to help users understand how each store's deal compares to the market
class StoreComparison {
  final String storeName;
  final double effectivePrice;
  final double savingsFromAverage;
  final double savingsPercentage;
  int rank;

  StoreComparison({
    required this.storeName,
    required this.effectivePrice,
    required this.savingsFromAverage,
    required this.savingsPercentage,
    required this.rank,
  });

  bool get isBelowAverage => savingsFromAverage > 0;
  bool get isAboveAverage => savingsFromAverage < 0;
  bool get isAverage => savingsFromAverage.abs() < 0.01; // Within 1 cent

  /// Get comparison description for UI
  String get comparisonDescription {
    if (isAverage) return 'At average price';
    if (isBelowAverage) {
      return 'Save €${savingsFromAverage.toStringAsFixed(2)} (${savingsPercentage.toStringAsFixed(1)}% below average)';
    } else {
      return 'Pay €${savingsFromAverage.abs().toStringAsFixed(2)} more (${savingsPercentage.abs().toStringAsFixed(1)}% above average)';
    }
  }

  /// Get rank description (1st, 2nd, 3rd, etc.)
  String get rankDescription {
    switch (rank) {
      case 1:
        return '1st - Best Deal';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }
}