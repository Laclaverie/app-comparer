import '../data_database.dart';
import '../extensions/product_extensions.dart';
import 'package:shared_models/productdto.dart';

class ProductService {
  final DataDatabase database;
  
  ProductService(this.database);

  // Méthodes avec logique métier
  Future<List<ProductDto>> getAllProducts() async {
    final products = await database.getAllProducts();
    return products.map((p) => p.toDto()).toList();
  }

  Future<ProductDto?> getProductByBarcode(int barcode) async {
    final product = await database.getProductByBarcode(barcode);
    return product?.toDto();
  }

  Future<ProductDto> createProduct(ProductDto dto) async {
    // Validation métier ici
    if (dto.name.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    
    // Vérifier si le barcode existe déjà
    final existing = await database.getProductByBarcode(dto.barcode);
    if (existing != null) {
      throw StateError('Product with barcode ${dto.barcode} already exists');
    }

    final companion = dto.toCompanion();
    final id = await database.insertProduct(companion);
    
    // Retourner le produit créé avec l'ID
    final created = await database.getProductById(id);
    return created!.toDto();
  }

  Future<ProductDto> updateProduct(ProductDto dto) async {
    if (dto.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    final companion = dto.toCompanion();
    await database.updateProduct(companion);
    
    final updated = await database.getProductById(dto.id!);
    return updated!.toDto();
  }

  Future<void> deleteProduct(int id) async {
    await database.deleteProduct(id);
  }

  Future<List<ProductDto>> searchProducts(String query) async {
    final products = await database.searchProducts(query);
    return products.map((p) => p.toDto()).toList();
  }
}