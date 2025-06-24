// packages/shared_models/lib/models/category/category_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  final int? id;
  final String name;
  final String? description;
  final int? parentId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryDto({
    this.id,
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _$CategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);

  CategoryDto copyWith({
    int? id,
    String? name,
    String? description,
    int? parentId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CategoryDto(id: $id, name: $name, isActive: $isActive)';
}