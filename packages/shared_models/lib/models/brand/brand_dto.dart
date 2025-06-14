// packages/shared_models/lib/models/brand/brand_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'brand_dto.g.dart';

@JsonSerializable()
class BrandDto {
  final int? id;
  final String name;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BrandDto({
    this.id,
    required this.name,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandDto.fromJson(Map<String, dynamic> json) => _$BrandDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BrandDtoToJson(this);

  BrandDto copyWith({
    int? id,
    String? name,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandDto(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'BrandDto(id: $id, name: $name, isActive: $isActive)';
}