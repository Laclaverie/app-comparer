// packages/shared_models/lib/models/product/product.dart

class Product {
  final int? id;
  final int barcode;
  final String name;
  final String? description;
  
  // ✅ RÉFÉRENCES par ID (cohérent avec tables)
  final int? brandId;
  final int? categoryId;
  
  // ✅ CHAMPS IMAGE complets
  final String? imageFileName;
  final String? imageUrl;
  final String? localImagePath;
  
  // ✅ MÉTADONNÉES complètes
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // ✅ OPTIONNEL : Noms résolus (pour affichage)
  final String? brandName;
  final String? categoryName;

  const Product({
    this.id,
    required this.barcode,
    required this.name,
    this.description,
    this.brandId,
    this.categoryId,
    this.imageFileName,
    this.imageUrl,
    this.localImagePath,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    // Noms résolus (optionnels)
    this.brandName,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      barcode: json['barcode'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      brandId: json['brandId'] as int?,
      categoryId: json['categoryId'] as int?,
      imageFileName: json['imageFileName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      localImagePath: json['localImagePath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      brandName: json['brandName'] as String?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'description': description,
      'brandId': brandId,
      'categoryId': categoryId,
      'imageFileName': imageFileName,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'brandName': brandName,
      'categoryName': categoryName,
    };
  }

  /// copyWith pour immutabilité
  Product copyWith({
    int? id,
    int? barcode,
    String? name,
    String? description,
    int? brandId,
    int? categoryId,
    String? imageFileName,
    String? imageUrl,
    String? localImagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brandName,
    String? categoryName,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      imageFileName: imageFileName ?? this.imageFileName,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brandName: brandName ?? this.brandName,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  // ✅ HELPERS métier
  bool get hasImage => imageUrl != null || localImagePath != null;
  bool get hasLocalImage => localImagePath != null;
  String get displayName => name.isEmpty ? 'Produit #$id' : name;
  bool get hasBrand => brandId != null;
  bool get hasCategory => categoryId != null;
  
  @override
  String toString() => 'Product(id: $id, name: $name, barcode: $barcode, isActive: $isActive)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && 
           other.id == id && 
           other.barcode == barcode;
  }

  @override
  int get hashCode => Object.hash(id, barcode);
}