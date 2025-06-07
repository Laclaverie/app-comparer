import 'promotion_type.dart';

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
}