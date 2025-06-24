import 'package:json_annotation/json_annotation.dart';

part 'supermarket_dto.g.dart';

@JsonSerializable()
class SupermarketDto {
  final int? id;
  final String name;
  final String? address;
  final String? city;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupermarketDto({
    this.id,
    required this.name,
    this.address,
    this.city,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SupermarketDto.fromJson(Map<String, dynamic> json) => _$SupermarketDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SupermarketDtoToJson(this);

  SupermarketDto copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupermarketDto(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'SupermarketDto(id: $id, name: $name, isActive: $isActive)';
}