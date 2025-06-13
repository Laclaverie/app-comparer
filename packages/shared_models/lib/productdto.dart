import 'package:json_annotation/json_annotation.dart';

part 'productdto.g.dart';

@JsonSerializable()
class ProductDto {  // ← DTO = Data Transfer Object
  final int? id;
  final int barcode;
  final String name;
  final int? brandId;
  final int? categoryId;
  final String? imageFileName;     // ← Nom du fichier image
  final String? imageUrl;          // ← URL pour téléchargement (généré par serveur)
  final String? localImagePath;    // ← Chemin local sur l'app client
  final String? description;

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
    );
  }
}