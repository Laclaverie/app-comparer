import 'package:data_server/extensions/price_extensions.dart';
import 'package:drift/drift.dart';
import 'package:shared_models/models/product/productdto.dart';
import 'package:shared_models/models/price/price_historydto.dart';
import 'package:shared_models/models/brand/brand_dto.dart';

import '../repositories/product_repository.dart';
import '../services/image_service.dart';
import '../extensions/product_extensions.dart';
import '../extensions/price_extensions.dart';


class ProductService {
  final ProductRepository repository;
  final ImageService imageService;
  
  ProductService(this.repository, this.imageService);

  // ✅ CRUD - Validation métier + conversion DTOs
  Future<List<ProductDto>> getAllProducts() async {
    final products = await repository.getAllProducts();
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<ProductDto?> getProductByBarcode(int barcode) async {
    if (barcode <= 0) {
      throw ArgumentError('Barcode must be positive');
    }
    
    final product = await repository.getProductByBarcode(barcode);
    return product?.toDtoWithImageUrl();
  }

  Future<ProductDto> createProduct(ProductDto dto) async {
    // Validation métier
    if (dto.name.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    
    if (dto.barcode <= 0) {
      throw ArgumentError('Valid barcode required');
    }
    
    // Vérifier unicité
    final existing = await repository.getProductByBarcode(dto.barcode);
    if (existing != null) {
      throw StateError('Product with barcode ${dto.barcode} already exists');
    }

    final companion = dto.toCompanion();
    await repository.insertProduct(companion);
    
    // Retourner le produit créé
    final created = await repository.getProductByBarcode(dto.barcode);
    return created!.toDtoWithImageUrl();
  }

  Future<ProductDto> updateProduct(ProductDto dto) async {
    // Validation métier
    if (dto.name.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    
    if (dto.barcode <= 0) {
      throw ArgumentError('Valid barcode required');
    }
    
    // Vérifier existence
    final existing = await repository.getProductByBarcode(dto.barcode);
    if (existing == null) {
      throw ArgumentError('Product with barcode ${dto.barcode} not found');
    }

    final companion = dto.toCompanion().copyWith(
      id: Value(existing.id),
      barcode: Value(dto.barcode),
    );
    
    final success = await repository.updateProduct(companion);
    if (!success) {
      throw StateError('Failed to update product with barcode ${dto.barcode}');
    }
    
    final updated = await repository.getProductByBarcode(dto.barcode);
    return updated!.toDtoWithImageUrl();
  }

  Future<void> deleteProductByBarcode(int barcode) async {
    if (barcode <= 0) {
      throw ArgumentError('Valid barcode required');
    }
    
    final product = await repository.getProductByBarcode(barcode);
    if (product == null) {
      throw ArgumentError('Product with barcode $barcode not found');
    }
    
    // Supprimer l'image si elle existe
    if (product.imageFileName != null) {
      await imageService.deleteImage(product.imageFileName!);
    }
    
    await repository.deleteProduct(product.id);
  }

  // ✅ RECHERCHE - Délégation + conversion DTOs
  Future<List<ProductDto>> searchProductsByBrand(String brandName, {int? limit}) async {
    final products = await repository.getProductsByBrandName(brandName, limit: limit);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<List<ProductDto>> searchProductsByBrands(List<String> brandNames, {int? limit}) async {
    final products = await repository.getProductsByBrandNames(brandNames, limit: limit);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<List<ProductDto>> searchProductsByBrandId(int brandId, {int? limit}) async {
    final products = await repository.getProductsByBrandId(brandId, limit: limit);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<List<ProductDto>> searchProductsByBrandIds(List<int> brandIds, {int? limit}) async {
    final products = await repository.getProductsByBrandIds(brandIds, limit: limit);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  Future<List<ProductDto>> getProductsByBarcodes(List<int> barcodes) async {
    final products = await repository.getProductsByBarcodes(barcodes);
    return products.map((p) => p.toDtoWithImageUrl()).toList();
  }

  // ✅ PRIX - Conversion vers DTOs métier
  Future<List<PriceHistoryDto>> getCurrentPricesByBarcode(int barcode, {List<String>? storeFilter}) async {
    final product = await repository.getProductByBarcode(barcode);
    if (product == null) {
      throw ArgumentError('Product with barcode $barcode not found');
    }

    final pricesWithStores = await repository.getCurrentPricesByProductId(product.id);
    
    // Filtrer par magasins si demandé
    List<PriceWithStoreResult> filtered = pricesWithStores;
    if (storeFilter != null && storeFilter.isNotEmpty) {
      filtered = pricesWithStores.where((pws) {
        if (pws.store == null) return false;
        return storeFilter.any((filter) => 
          pws.store!.name.toLowerCase().contains(filter.toLowerCase())
        );
      }).toList();
    }
    
    return filtered.map((pws) => _convertToDto(pws)).toList();
  }

  Future<List<PriceHistoryDto>> getPriceHistoryByBarcode(
    int barcode, {
    String? storeFilter,
    DateTime? since,
    int limitDays = 30,
    List<String>? storeNames,
  }) async {
    final product = await repository.getProductByBarcode(barcode);
    if (product == null) {
      throw ArgumentError('Product with barcode $barcode not found');
    }

    final pricesWithStores = await repository.getPriceHistoryByProductId(
      product.id,
      storeFilter: storeFilter,
      since: since,
      limitDays: limitDays,
      storeNames: storeNames,
    );
    
    return pricesWithStores.map((pws) => _convertToDto(pws)).toList();
  }

  // ✅ MARQUES
  Future<List<BrandDto>> getAllBrands() async {
    final brands = await repository.getAllBrands();
    return brands.map((b) => BrandDto(id: b.id, name: b.name)).toList();
  }

  Future<List<BrandDto>> searchBrands(String query, {int limit = 20}) async {
    final brands = await repository.searchBrandsByName(query, limit: limit);
    return brands.map((b) => BrandDto(id: b.id, name: b.name)).toList();
  }

  // ✅ HELPER PRIVÉ - Conversion PriceWithStoreResult → PriceHistoryDto
  PriceHistoryDto _convertToDto(PriceWithStoreResult data) {
    String? storeLocation;
    if (data.store != null) {
      final parts = <String>[];
      if (data.store!.address?.isNotEmpty == true) {
        parts.add(data.store!.address!);
      }
      if (data.store!.city?.isNotEmpty == true) {
        parts.add(data.store!.city!);
      }
      storeLocation = parts.isNotEmpty ? parts.join(', ') : null;
    }
    
    return data.price.toDto(
      storeName: data.store?.name,
      storeLocation: storeLocation,
    );
  }
}