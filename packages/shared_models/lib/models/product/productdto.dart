import 'package:json_annotation/json_annotation.dart';

part 'productdto.g.dart';

@JsonSerializable()
class ProductDto {
  final int? id;
  final int barcode;           // ✅ Reste int
  final String name;
  final int? brandId;          // ✅ ID au lieu de String
  final int? categoryId;       // ✅ ID au lieu de String
  final String? imageFileName;
  final String? imageUrl;
  final String? localImagePath;
  final String? description;
  
  // ✅ AJOUTS demandés
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDto({
    this.id,
    required this.barcode,
    required this.name,
    this.brandId,
    this.categoryId,
    this.imageFileName,
    this.imageUrl,
    this.localImagePath,
    this.description,
    this.isActive = true,        // ✅ Défaut à true
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => _$ProductDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);
  
  ProductDto copyWith({
    int? id,
    int? barcode,
    String? name,
    int? brandId,
    int? categoryId,
    String? imageFileName,
    String? imageUrl,
    String? localImagePath,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductDto(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      imageFileName: imageFileName ?? this.imageFileName,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ProductDto(id: $id, name: $name, barcode: $barcode, isActive: $isActive)';
}