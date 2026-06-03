import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  final String type;
  final String name;
  final String? icon;
  final String? color;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'is_default', fromJson: _boolFromJson)
  final bool isDefault;
  final List<CategoryDto>? children;

  CategoryDto({
    required this.id,
    this.userId,
    this.parentId,
    required this.type,
    required this.name,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.isDefault,
    this.children,
  });

  static bool _boolFromJson(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _$CategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);
}
