import 'package:json_annotation/json_annotation.dart';

part 'statistics_models.g.dart';

/// Represents the statistical distribution of prices across different stores
/// Provides quartile analysis, outlier detection, and price range grouping
/// Used to analyze how prices are clustered across different price bands
@JsonSerializable()
class PriceDistribution {
  final List<double> quartiles;
  final List<double> outliers;

  @JsonKey(name: 'price_ranges')
  final List<PriceRange> priceRanges;

  PriceDistribution({
    required this.quartiles,
    required this.outliers,
    required this.priceRanges,
  });

  /// Get interquartile range (Q3 - Q1)
  double get interquartileRange => quartiles[2] - quartiles[0];

  /// Get median (Q2)
  double get median => quartiles[1];

  /// Check if distribution has outliers
  bool get hasOutliers => outliers.isNotEmpty;

  /// Get the most common price range
  PriceRange? get mostCommonRange {
    if (priceRanges.isEmpty) return null;
    return priceRanges.reduce((a, b) => a.count > b.count ? a : b);
  }

  factory PriceDistribution.fromJson(Map<String, dynamic> json) => _$PriceDistributionFromJson(json);
  Map<String, dynamic> toJson() => _$PriceDistributionToJson(this);
}

/// Represents a specific price range with its frequency distribution
/// Used to analyze how prices are clustered across different price bands
/// Helpful for market analysis and identifying pricing patterns
@JsonSerializable()
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

  /// Get range label for display
  String get label => '€${min.toStringAsFixed(2)} - €${max.toStringAsFixed(2)}';

  /// Get range width
  double get width => max - min;

  /// Check if a price falls within this range
  bool contains(double price) => price >= min && price <= max;

  factory PriceRange.fromJson(Map<String, dynamic> json) => _$PriceRangeFromJson(json);
  Map<String, dynamic> toJson() => _$PriceRangeToJson(this);
}