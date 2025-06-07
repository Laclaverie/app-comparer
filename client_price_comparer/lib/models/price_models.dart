/// Represents a historical price data point at a specific date and store
/// Used for tracking price changes over time and building price history charts
/// Contains timestamp, price value, store information, and any active promotions
class PricePoint {
  final DateTime date;
  final double price;
  final String? storeName;
  final PricePromotion? promotion;

  PricePoint({
    required this.date,
    required this.price,
    this.storeName,
    this.promotion,
  });

  /// Get the effective price considering promotions
  double get effectivePrice {
    if (promotion == null) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: DateTime.parse(json['date']),
      price: json['price'].toDouble(),
      storeName: json['storeName'],
      promotion: json['promotion'] != null 
          ? PricePromotion.fromJson(json['promotion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'price': price,
      'storeName': storeName,
      'promotion': promotion?.toJson(),
    };
  }
}

/// Defines the different types of promotional offers available
/// Each type represents a different discount mechanism with specific parameters
enum PromotionType {
  percentageDiscount,     // 20% off
  fixedDiscount,         // €2 off
  buyXGetY,              // Buy 3 get 4
  buyXForY,              // 2 for €5
  multipleQuantity,      // 3 for €10
}

/// Represents a promotional offer applied to a product price
/// Contains promotion details, validity periods, and parameters for different discount types
/// Used to calculate effective prices and display promotional information to users
class PricePromotion {
  final PromotionType type;
  final String description;
  final Map<String, dynamic> parameters;
  final DateTime? validFrom;
  final DateTime? validTo;

  PricePromotion({
    required this.type,
    required this.description,
    required this.parameters,
    this.validFrom,
    this.validTo,
  });

  /// Factory constructor to create a PricePromotion from JSON
  factory PricePromotion.fromJson(Map<String, dynamic> json) {
    return PricePromotion(
      type: PromotionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PromotionType.percentageDiscount,
      ),
      description: json['description'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      validFrom: json['validFrom'] != null ? DateTime.parse(json['validFrom']) : null,
      validTo: json['validTo'] != null ? DateTime.parse(json['validTo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'description': description,
      'parameters': parameters,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
    };
  }

  /// Calculate the effective price per unit considering the promotion
  double calculateEffectivePrice(double basePrice) {
    switch (type) {
      case PromotionType.percentageDiscount:
        final discount = parameters['percentage'] as double;
        return basePrice * (1 - discount / 100);
        
      case PromotionType.fixedDiscount:
        final discount = parameters['amount'] as double;
        return (basePrice - discount).clamp(0, double.infinity);
        
      case PromotionType.buyXGetY:
        final buyQuantity = parameters['buyQuantity'] as int;
        final getQuantity = parameters['getQuantity'] as int;
        final totalUnits = buyQuantity + getQuantity;
        // Example: Buy 3, Get 4 total = pay for 3, get 4 = 3/4 = 0.75 of original price
        return basePrice * buyQuantity / totalUnits;
        
      case PromotionType.buyXForY:
        final quantity = parameters['quantity'] as int;
        final totalPrice = parameters['totalPrice'] as double;
        return totalPrice / quantity;
        
      case PromotionType.multipleQuantity:
        final quantity = parameters['quantity'] as int;
        final totalPrice = parameters['totalPrice'] as double;
        return totalPrice / quantity;
    }
  }

  /// Get the minimum quantity needed to benefit from the deal
  int get minimumQuantity {
    switch (type) {
      case PromotionType.percentageDiscount:
      case PromotionType.fixedDiscount:
        return 1; // Applies to any quantity
        
      case PromotionType.buyXGetY:
        return parameters['buyQuantity'] as int;
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        return parameters['quantity'] as int;
    }
  }

  /// Get savings percentage for display
  double getSavingsPercentage(double basePrice) {
    final effectivePrice = calculateEffectivePrice(basePrice);
    return ((basePrice - effectivePrice) / basePrice) * 100;
  }

  /// Get detailed explanation with conditions
  String getDetailedExplanation(double basePrice) {
    final effectivePrice = calculateEffectivePrice(basePrice);
 //   final savings = basePrice - effectivePrice;
    final savingsPercentage = getSavingsPercentage(basePrice);

    switch (type) {
      case PromotionType.percentageDiscount:
        return 'Save ${savingsPercentage.toStringAsFixed(1)}% on any quantity';
        
      case PromotionType.fixedDiscount:
        final discount = parameters['amount'] as double;
        return 'Save €${discount.toStringAsFixed(2)} on any quantity';
        
      case PromotionType.buyXGetY:
        final buyQuantity = parameters['buyQuantity'] as int;
        final getQuantity = parameters['getQuantity'] as int;
        final totalQuantity = buyQuantity + getQuantity;
        return 'Buy $buyQuantity, get $totalQuantity total (${savingsPercentage.toStringAsFixed(1)}% per unit when buying minimum $buyQuantity)';
        
      case PromotionType.buyXForY:
        final quantity = parameters['quantity'] as int;
        final totalPrice = parameters['totalPrice'] as double;
        return '$quantity for €${totalPrice.toStringAsFixed(2)} (€${effectivePrice.toStringAsFixed(2)}/unit when buying $quantity)';
        
      case PromotionType.multipleQuantity:
        final quantity = parameters['quantity'] as int;
        final totalPrice = parameters['totalPrice'] as double;
        return '$quantity for €${totalPrice.toStringAsFixed(2)} (minimum $quantity required)';
    }
  }

  /// Get simple promotion explanation for unit price
  String getPromotionExplanation(double basePrice) {
    final savingsPercentage = getSavingsPercentage(basePrice);

    switch (type) {
      case PromotionType.percentageDiscount:
      case PromotionType.fixedDiscount:
        return 'Save ${savingsPercentage.toStringAsFixed(1)}%';
        
      case PromotionType.buyXGetY:
        final buyQuantity = parameters['buyQuantity'] as int;
        return 'Save ${savingsPercentage.toStringAsFixed(1)}% per unit (min. $buyQuantity)';
        
      case PromotionType.buyXForY:
      case PromotionType.multipleQuantity:
        final quantity = parameters['quantity'] as int;
        return 'Effective when buying $quantity';
    }
  }

  /// Check if promotion is currently valid
  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return true;
  }
}

/// Represents a product price at a specific store with promotion and timestamp information
/// Core data model for price comparison functionality across different retailers
/// Tracks current user's store preference and promotional offers
class StorePrice {
  final String storeName;
  final double price;
  final bool isCurrentStore;
  final DateTime lastUpdated;
  final PricePromotion? promotion;

  StorePrice({
    required this.storeName,
    required this.price,
    required this.isCurrentStore,
    required this.lastUpdated,
    this.promotion,
  });

  /// Get the effective price considering promotions
  double get effectivePrice {
    if (promotion == null || !promotion!.isValid) return price;
    return promotion!.calculateEffectivePrice(price);
  }

  /// Get the best deal description including promotion details
  String get dealDescription {
    if (promotion == null || !promotion!.isValid) {
      return '€${price.toStringAsFixed(2)} at $storeName';
    }
    
    return '€${effectivePrice.toStringAsFixed(2)} at $storeName (${promotion!.description})';
  }

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    return StorePrice(
      storeName: json['storeName'],
      price: json['price'].toDouble(),
      isCurrentStore: json['isCurrentStore'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      promotion: json['promotion'] != null 
          ? PricePromotion.fromJson(json['promotion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'price': price,
      'isCurrentStore': isCurrentStore,
      'lastUpdated': lastUpdated.toIso8601String(),
      'promotion': promotion?.toJson(),
    };
  }
}

/// Contains comprehensive statistical analysis of product prices across multiple stores
/// Provides essential metrics like averages, variance, and price volatility indicators
/// Used for market analysis, price trend detection, and helping users understand deal quality
class ProductStatistics {
  final double averagePrice;
  final double medianPrice;
  final double minPrice;
  final double maxPrice;
  final double priceVariance;
  final StorePrice bestDeal;
  final StorePrice worstDeal;

  ProductStatistics({
    required this.averagePrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceVariance,
    required this.bestDeal,
    required this.worstDeal,
  });

  String get bestDealExplanation {
    if (bestDeal.promotion == null || !bestDeal.promotion!.isValid) {
      return 'Regular price: €${bestDeal.price.toStringAsFixed(2)} at ${bestDeal.storeName}';
    }
    
    return '${bestDeal.promotion!.getPromotionExplanation(bestDeal.price)} at ${bestDeal.storeName}';
  }

  String get worstDealExplanation {
    if (worstDeal.promotion == null || !worstDeal.promotion!.isValid) {
      return 'Regular price: €${worstDeal.price.toStringAsFixed(2)} at ${worstDeal.storeName}';
    }
    
    return 'Even with promotion (${worstDeal.promotion!.description}): €${worstDeal.effectivePrice.toStringAsFixed(2)} at ${worstDeal.storeName}';
  }
}

/// Defines display modes for product information in the user interface
/// Controls the level of detail shown to users based on their preferences
enum ProductDisplayMode {
  minimal,
  advanced,
}