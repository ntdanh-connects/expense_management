import 'package:json_annotation/json_annotation.dart';

part 'report_category_dto.g.dart';

@JsonSerializable()
class ReportCategoryEntryDto {
  @JsonKey(name: 'category_id')
  final String categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  @JsonKey(name: 'category_color')
  final String? categoryColor;
  @JsonKey(name: 'category_icon')
  final String? categoryIcon;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @JsonKey(name: 'parent_name')
  final String? parentName;
  final double amount;
  final double percentage;

  ReportCategoryEntryDto({
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.parentId,
    this.parentName,
    required this.amount,
    required this.percentage,
  });

  factory ReportCategoryEntryDto.fromJson(Map<String, dynamic> json) => _$ReportCategoryEntryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportCategoryEntryDtoToJson(this);
}

@JsonSerializable()
class ReportCategoryDto {
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final List<ReportCategoryEntryDto> categories;

  ReportCategoryDto({
    required this.totalAmount,
    required this.categories,
  });

  factory ReportCategoryDto.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    List<dynamic> categoriesList = [];
    if (rawCategories is List) {
      categoriesList = rawCategories;
    } else if (rawCategories is Map) {
      categoriesList = rawCategories.values.toList();
    }
    return ReportCategoryDto(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      categories: categoriesList
          .map((e) => ReportCategoryEntryDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$ReportCategoryDtoToJson(this);
}
