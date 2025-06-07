import 'package:json_annotation/json_annotation.dart';
import 'promotion_type.dart';

part 'price_promotion.g.dart';

/// Represents a promotional offer applied to a product price
/// Contains promotion details, validity periods, and parameters for different discount types
/// Used to calculate effective prices and display promotional information to users
@JsonSerializable()
class PricePromotion {
  final PromotionType type;
  final String description;
  
  // Keep the flexible Map but add type-safe getters
  final Map<String, dynamic> parameters;
  
  @JsonKey(name: 'valid_from')
  final DateTime? validFrom;
  
  @JsonKey(name: 'valid_to')
  final DateTime? validTo;

  PricePromotion({
    required this.type,
    required this.description,
    required this.parameters,
    this.validFrom,
    this.validTo,
  });

  // ====== TYPE-SAFE GETTERS ======
  
  /// Safe getter for percentage discount
  double? get percentage {
    if (type != PromotionType.percentageDiscount) return null;
    final value = parameters['percentage'];
    return value is num ? value.toDouble() : null;
  }

  /// Safe getter for fixed discount amount
  double? get discountAmount {
    if (type != PromotionType.fixedDiscount) return null;
    final value = parameters['amount'];
    return value is num ? value.toDouble() : null;
  }

  /// Safe getter for buy quantity (Buy X Get Y)
  int? get buyQuantity {
    if (type != PromotionType.buyXGetY) return null;
    final value = parameters['buyQuantity'];
    return value is int ? value : null;
  }

  /// Safe getter for get quantity (Buy X Get Y)
  int? get getQuantity {
    if (type != PromotionType.buyXGetY) return null;
    final value = parameters['getQuantity'];
    return value is int ? value : null;
  }

  /// Safe getter for bundle quantity (Buy X for Y)
  int? get bundleQuantity {
    if (type != PromotionType.buyXForY && type != PromotionType.multipleQuantity) return null;
    final value = parameters['quantity'];
    return value is int ? value : null;
  }

  /// Safe getter for total price (Buy X for Y, Multiple Quantity)
  double? get totalPrice {
    if (type != PromotionType.buyXForY && type != PromotionType.multipleQuantity) return null;
    final value = parameters['totalPrice'];
    return value is num ? value.toDouble() : null;
  }

  // ====== VALIDATION METHODS ======
  
  /// Check if this promotion has valid parameters for its type
  bool get hasValidParameters {
    switch (type) {
      case PromotionType.percentageDiscount:
        return percentage != null;
      case PromotionType.fixedDiscount:
        return discountAmount != null;
      case PromotionType.buyXGetY:
        return buyQuantity != null && getQuantity != null;
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        return bundleQuantity != null && totalPrice != null;
    }
  }

  /// Get a description of what parameters are missing
  String? get parameterValidationError {
    if (hasValidParameters) return null;
    
    switch (type) {
      case PromotionType.percentageDiscount:
        return 'Missing or invalid percentage parameter';
      case PromotionType.fixedDiscount:
        return 'Missing or invalid amount parameter';
      case PromotionType.buyXGetY:
        return 'Missing or invalid buyQuantity/getQuantity parameters';
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        return 'Missing or invalid quantity/totalPrice parameters';
    }
  }

  // ====== BUSINESS LOGIC METHODS ======
  
  /// Calculate the effective price per unit considering the promotion
  double calculateEffectivePrice(double basePrice) {
    switch (type) {
      case PromotionType.percentageDiscount:
        final discount = percentage;
        if (discount == null) return basePrice;
        return basePrice * (1 - discount / 100);
        
      case PromotionType.fixedDiscount:
        final discount = discountAmount;
        if (discount == null) return basePrice;
        return (basePrice - discount).clamp(0, double.infinity);
        
      case PromotionType.buyXGetY:
        final buyQty = buyQuantity;
        final getQty = getQuantity;
        if (buyQty == null || getQty == null) return basePrice;
        final totalUnits = buyQty + getQty;
        return basePrice * buyQty / totalUnits;
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        final quantity = bundleQuantity;
        final total = totalPrice;
        if (quantity == null || total == null) return basePrice;
        return total / quantity;
    }
  }

  /// Get savings percentage for display
  double getSavingsPercentage(double basePrice) {
    final effectivePrice = calculateEffectivePrice(basePrice);
    if (basePrice == 0) return 0;
    return ((basePrice - effectivePrice) / basePrice) * 100;
  }

  /// Check if promotion is currently valid
  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return hasValidParameters;
  }

  /// Get simple promotion explanation for unit price
  String getPromotionExplanation(double basePrice) {
    final savingsPercentage = getSavingsPercentage(basePrice);

    switch (type) {
      case PromotionType.percentageDiscount:
      case PromotionType.fixedDiscount:
        return 'Save ${savingsPercentage.toStringAsFixed(1)}%';
        
      case PromotionType.buyXGetY:
        final buyQty = buyQuantity ?? 0;
        return 'Save ${savingsPercentage.toStringAsFixed(1)}% per unit (min. $buyQty)';
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        final quantity = bundleQuantity ?? 0;
        return 'Effective when buying $quantity';
    }
  }

  /// Get detailed explanation with conditions
  String getDetailedExplanation(double basePrice) {
    final effectivePrice = calculateEffectivePrice(basePrice);
    final savingsPercentage = getSavingsPercentage(basePrice);

    switch (type) {
      case PromotionType.percentageDiscount:
        return 'Save ${savingsPercentage.toStringAsFixed(1)}% on any quantity';
        
      case PromotionType.fixedDiscount:
        final discount = discountAmount ?? 0;
        return 'Save €${discount.toStringAsFixed(2)} on any quantity';
        
      case PromotionType.buyXGetY:
        final buyQty = buyQuantity ?? 0;
        final getQty = getQuantity ?? 0;
        final totalQuantity = buyQty + getQty;
        return 'Buy $buyQty, get $totalQuantity total (${savingsPercentage.toStringAsFixed(1)}% per unit when buying minimum $buyQty)';
        
      case PromotionType.buyXForY:
        final quantity = bundleQuantity ?? 0;
        final total = totalPrice ?? 0;
        return '$quantity for €${total.toStringAsFixed(2)} (€${effectivePrice.toStringAsFixed(2)}/unit when buying exactly $quantity)';
        
      case PromotionType.multipleQuantity:
        final quantity = bundleQuantity ?? 0;
        final total = totalPrice ?? 0;
        return '$quantity+ for €${total.toStringAsFixed(2)} each (€${effectivePrice.toStringAsFixed(2)}/unit when buying $quantity or more)';
    }
  }

  // ====== FACTORY CONSTRUCTORS ======
  // Easy creation with validation
  
  /// Create a percentage discount promotion
  factory PricePromotion.percentageDiscount({
    required String description,
    required double percentage,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    if (percentage < 0 || percentage > 100) {
      throw ArgumentError('Percentage must be between 0 and 100');
    }
    
    return PricePromotion(
      type: PromotionType.percentageDiscount,
      description: description,
      parameters: {'percentage': percentage},
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  /// Create a fixed discount promotion
  factory PricePromotion.fixedDiscount({
    required String description,
    required double amount,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    if (amount < 0) {
      throw ArgumentError('Discount amount cannot be negative');
    }
    
    return PricePromotion(
      type: PromotionType.fixedDiscount,
      description: description,
      parameters: {'amount': amount},
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  /// Create a buy X get Y promotion
  factory PricePromotion.buyXGetY({
    required String description,
    required int buyQuantity,
    required int getQuantity,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    if (buyQuantity <= 0 || getQuantity <= 0) {
      throw ArgumentError('Quantities must be positive');
    }
    
    return PricePromotion(
      type: PromotionType.buyXGetY,
      description: description,
      parameters: {
        'buyQuantity': buyQuantity,
        'getQuantity': getQuantity,
      },
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  /// Create a bundle pricing promotion
  factory PricePromotion.buyXForY({
    required String description,
    required int quantity,
    required double totalPrice,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    if (quantity <= 0 || totalPrice <= 0) {
      throw ArgumentError('Quantity and price must be positive');
    }
    
    return PricePromotion(
      type: PromotionType.buyXForY,
      description: description,
      parameters: {
        'quantity': quantity,
        'totalPrice': totalPrice,
      },
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  factory PricePromotion.fromJson(Map<String, dynamic> json) => _$PricePromotionFromJson(json);
  Map<String, dynamic> toJson() => _$PricePromotionToJson(this);
}