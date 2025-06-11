import '../data_database.dart';
import '../extensions/product_extensions.dart';
import 'package:shared_models/productdto.dart';
import 'package:data_server/services/image_service.dart';

class ProductService {
  final DataDatabase database;
  final ImageService imageService;
  
  ProductService(this.database, this.imageService);

  // Méthodes avec logique métier
  Future<List<ProductDto>> getAllProducts() async {
    final products = await database.getAllProducts();
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<ProductDto?> getProductByBarcode(int barcode) async {
    final product = await database.getProductByBarcode(barcode);
    return product?.toDtoWithImageUrl();
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
    
    // Retourner le produit créé avec l'URL d'image
    final created = await database.getProductById(id);
    return created!.toDtoWithImageUrl();
  }

  Future<ProductDto> updateProduct(ProductDto dto) async {
    if (dto.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    final companion = dto.toCompanion();
    await database.updateProduct(companion);
    
    final updated = await database.getProductById(dto.id!);
    return updated!.toDtoWithImageUrl();
  }

  Future<void> deleteProduct(int id) async {
    // Récupérer le produit pour obtenir le nom de l'image
    final product = await database.getProductById(id);
    
    // Supprimer le produit de la DB
    await database.deleteProduct(id);
    
    // Supprimer les fichiers image s'ils existent
    if (product?.imageFileName != null) {
      await imageService.deleteImage(product!.imageFileName!);
    }
  }

  Future<List<ProductDto>> searchProducts(String query) async {
    final products = await database.searchProducts(query);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }
}