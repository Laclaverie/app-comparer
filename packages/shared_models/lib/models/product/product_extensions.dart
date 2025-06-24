import 'package:shared_models/models/product/product.dart';
import 'package:shared_models/models/product/productdto.dart';

/// Extensions pour conversion Product ↔ ProductDto
extension ProductDtoExtensions on ProductDto {
  /// Convertit un ProductDto vers Product (business model)
  Product toBusinessModel({
    String? brandName,
    String? categoryName,
  }) {
    return Product(
      id: id,
      barcode: barcode,
      name: name,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      imageFileName: imageFileName,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      brandName: brandName,
      categoryName: categoryName,
    );
  }
  
  /// Validation du ProductDto
  bool get isValid {
    return name.isNotEmpty && 
           name.length <= 255 &&
           barcode > 0;
  }
  
  /// Version pour API (sans champs client-specific)
  ProductDto toApiVersion() {
    return copyWith(
      localImagePath: null,  // Pas besoin côté serveur
    );
  }
}

extension ProductExtensions on Product {
  /// Convertit un Product vers ProductDto
  ProductDto toDto() {
    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      imageFileName: imageFileName,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  /// Version sans enrichissement (IDs seulement)
  Product withoutEnrichment() {
    return copyWith(
      brandName: null,
      categoryName: null,
    );
  }
}