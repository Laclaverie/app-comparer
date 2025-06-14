import 'package:shared_models/models/product/productdto.dart';
import 'package:drift/drift.dart';
import '../data_database.dart';

extension ProductToDto on Product {
  ProductDto toDto() {
    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      brandId: brandId,
      categoryId: categoryId,
      imageFileName: imageFileName,
      description: description,
    );
  }

  ProductDto toDtoWithImageUrl() {
    String? imageUrl;
    if (imageFileName != null) {
      imageUrl = '/api/images/compressed/$imageFileName';
    }

    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      brandId: brandId,
      categoryId: categoryId,
      imageFileName: imageFileName,
      imageUrl: imageUrl, // ← URL pour téléchargement
      description: description,
    );
  }
}

extension ProductDtoToCompanion on ProductDto {
  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      barcode: Value(barcode),
      name: Value(name),
      brandId: brandId != null ? Value(brandId!) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId!) : const Value.absent(),
      imageFileName: imageFileName != null ? Value(imageFileName!) : const Value.absent(),
      imagePath: const Value.absent(), // Géré par le serveur
      description: description != null ? Value(description!) : const Value.absent(),
    );
  }
}