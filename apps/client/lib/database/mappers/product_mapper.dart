// apps/client/lib/database/mappers/product_mapper.dart

import 'package:drift/drift.dart' show Value;
import 'package:shared_models/models/product/productdto.dart';
import '../app_database.dart';

/// Extensions pour conversion entre Drift Product et ProductDto
extension ProductDriftMapper on Product {
  /// Convertit un Product Drift vers DTO API
  ProductDto toDto() {
    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convertit un Product Drift vers DTO API (sans champs cache)
  ProductDto toDtoForSync() {
    return ProductDto(
      id: id,
      barcode: barcode,
      name: name,
      description: description,
      brandId: brandId,
      categoryId: categoryId,
      imageUrl: imageUrl,
      // ❌ Pas localImagePath pour le serveur
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ProductDtoMapper on ProductDto {
  /// Convertit un DTO API vers ProductsCompanion Drift
  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      barcode: Value(barcode),
      name: Value(name),
      description: Value(description),
      brandId: Value(brandId),
      categoryId: Value(categoryId),
      imageUrl: Value(imageUrl),
      localImagePath: Value(localImagePath),
      isActive: Value(isActive),
      createdAt: createdAt != null ? Value(createdAt!) : const Value.absent(),
      updatedAt: updatedAt != null ? Value(updatedAt!) : const Value.absent(),
      // Champs cache initialisés côté client
      lastSyncedAt: Value(DateTime.now()),
      isCachedLocally: const Value(true),
      scanCount: const Value(0),
    );
  }

  /// Met à jour un Product existant avec des données du serveur
  ProductsCompanion toUpdateCompanion({
    required int existingId,
    DateTime? lastScannedAt,
    int? scanCount,
    bool? isCachedLocally,
  }) {
    return ProductsCompanion(
      id: Value(existingId),
      barcode: Value(barcode),
      name: Value(name),
      description: Value(description),
      brandId: Value(brandId),
      categoryId: Value(categoryId),
      imageUrl: Value(imageUrl),
      localImagePath: Value(localImagePath),
      isActive: Value(isActive),
      updatedAt: updatedAt != null ? Value(updatedAt!) : Value(DateTime.now()),
      lastSyncedAt: Value(DateTime.now()),
      // Préserver les données locales
      lastScannedAt: lastScannedAt != null ? Value(lastScannedAt) : const Value.absent(),
      scanCount: scanCount != null ? Value(scanCount) : const Value.absent(),
      isCachedLocally: isCachedLocally != null ? Value(isCachedLocally) : const Value.absent(),
    );
  }

  /// Pour insertion avec génération automatique d'ID
  ProductsCompanion toInsertCompanion() {
    return ProductsCompanion.insert(
      barcode: barcode,
      name: name,
      description: Value(description),
      brandId: Value(brandId),
      categoryId: Value(categoryId),
      imageUrl: Value(imageUrl),
      localImagePath: Value(localImagePath),
      isActive: Value(isActive),
      // Timestamps automatiques
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      // Cache initial
      isCachedLocally: const Value(true),
    );
  }
}