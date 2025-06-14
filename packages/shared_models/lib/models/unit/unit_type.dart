// packages/shared_models/lib/models/unit/unit_type.dart
import 'package:json_annotation/json_annotation.dart';

/// Defines the different unit types for price comparison calculations
/// Used to normalize prices across different product sizes and formats
enum UnitType {
  /// Price per 100 grams - standard for solid foods
  /// Example: €2.50/100g for comparing different package sizes
  @JsonValue('per_100g')
  per100g,
  
  /// Price per kilogram - for larger quantities
  /// Example: €25.00/kg for bulk items
  @JsonValue('per_kg')
  perKg,
  
  /// Price per 100 milliliters - standard for liquids
  /// Example: €1.20/100ml for beverages, oils, etc.
  @JsonValue('per_100ml')
  per100ml,
  
  /// Price per liter - for larger liquid quantities
  /// Example: €12.00/L for bulk liquids
  @JsonValue('per_liter')
  perLiter,
  
  /// Price per individual unit/piece
  /// Example: €0.50/piece for items sold individually
  @JsonValue('per_piece')
  perPiece,
  
  /// Price per meter - for materials, cables, etc.
  /// Example: €5.00/m for fabric or wire
  @JsonValue('per_meter')
  perMeter,
  
  /// Price per square meter - for surfaces, tiles, etc.
  /// Example: €15.00/m² for flooring
  @JsonValue('per_square_meter')
  perSquareMeter,
}

/// Extension to provide display strings and conversion factors
extension UnitTypeExtension on UnitType {
  /// Human-readable display string
  String get displayName {
    switch (this) {
      case UnitType.per100g:
        return 'per 100g';
      case UnitType.perKg:
        return 'per kg';
      case UnitType.per100ml:
        return 'per 100ml';
      case UnitType.perLiter:
        return 'per L';
      case UnitType.perPiece:
        return 'per piece';
      case UnitType.perMeter:
        return 'per m';
      case UnitType.perSquareMeter:
        return 'per m²';
    }
  }
  
  /// Short symbol for UI display
  String get symbol {
    switch (this) {
      case UnitType.per100g:
        return '/100g';
      case UnitType.perKg:
        return '/kg';
      case UnitType.per100ml:
        return '/100ml';
      case UnitType.perLiter:
        return '/L';
      case UnitType.perPiece:
        return '/pc';
      case UnitType.perMeter:
        return '/m';
      case UnitType.perSquareMeter:
        return '/m²';
    }
  }
  
  /// Check if this unit type is compatible with weight-based products
  bool get isWeightBased => this == UnitType.per100g || this == UnitType.perKg;
  
  /// Check if this unit type is compatible with volume-based products
  bool get isVolumeBased => this == UnitType.per100ml || this == UnitType.perLiter;
}