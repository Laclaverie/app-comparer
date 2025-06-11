import 'package:shared_models/productdto.dart';
import 'package:drift/drift.dart'; 
import '../data_database.dart';

extension ProductToDto on Product {  // Drift Product → DTO
  ProductDto toDto() {
    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      brandId: brandId,
      categoryId: categoryId,
      imageUrl: imageUrl,
      description: description,
    );
  }
}

extension ProductDtoToCompanion on ProductDto {  // DTO → Drift Companion
  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      barcode: Value(barcode),
      name: Value(name),
      brandId: brandId != null ? Value(brandId!) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId!) : const Value.absent(),
      imageUrl: imageUrl != null ? Value(imageUrl!) : const Value.absent(),
      description: description != null ? Value(description!) : const Value.absent(),
    );
  }
}