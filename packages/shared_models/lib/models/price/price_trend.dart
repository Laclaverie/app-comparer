import 'package:json_annotation/json_annotation.dart';

part 'price_trend.g.dart';

/// Defines the possible directions a price trend can take over time
enum TrendDirection {
  @JsonValue('increasing')
  increasing,
  
  @JsonValue('decreasing')
  decreasing,
  
  @JsonValue('stable')
  stable,
  
  @JsonValue('volatile')
  volatile,
}

/// Represents price movement analysis over a specific time period
/// Tracks direction, magnitude, and strength of price changes for trend analysis
/// Used to help users understand if prices are going up, down, or remaining stable
@JsonSerializable()
class PriceTrend {
  final TrendDirection direction;
  
  @JsonKey(name: 'change_amount')
  final double changeAmount;
  
  @JsonKey(name: 'change_percentage')
  final double changePercentage;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  @JsonKey(name: 'historical_prices')
  final List<double> historicalPrices;
  
  @JsonKey(name: 'trend_strength')
  final double trendStrength;

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

  factory PriceTrend.fromJson(Map<String, dynamic> json) => _$PriceTrendFromJson(json);
  Map<String, dynamic> toJson() => _$PriceTrendToJson(this);
}