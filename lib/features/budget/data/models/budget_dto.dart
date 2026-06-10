import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'budget_dto.g.dart';

@JsonSerializable()
class BudgetDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @JsonKey(name: 'limit_amount', fromJson: _doubleFromJson)
  final double limitAmount;
  final int month;
  final int year;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'used_amount', fromJson: _doubleFromJson)
  final double usedAmount;
  final CategoryDto? category;

  BudgetDto({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.limitAmount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
    required this.usedAmount,
    this.category,
  });

  static double _doubleFromJson(dynamic val) {
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    if (json['used_amount'] == null && json['usage'] != null && json['usage']['used_amount'] != null) {
      json['used_amount'] = json['usage']['used_amount'];
    }
    return _$BudgetDtoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$BudgetDtoToJson(this);
}
