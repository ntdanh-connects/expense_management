import 'package:json_annotation/json_annotation.dart';

part 'recurring_rule_dto.g.dart';

@JsonSerializable()
class RecurringRuleDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'wallet_id')
  final String walletId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final String type;
  @JsonKey(fromJson: _amountFromJson)
  final double amount;
  final String title;
  final String frequency;
  @JsonKey(name: 'interval_value')
  final int? intervalValue;
  @JsonKey(name: 'start_date', fromJson: _dateFromJson)
  final DateTime? startDate;
  @JsonKey(name: 'next_run_at', fromJson: _dateFromJson)
  final DateTime? nextRunAt;
  @JsonKey(name: 'end_at', fromJson: _dateFromJson)
  final DateTime? endAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_executed_at', fromJson: _dateFromJson)
  final DateTime? lastExecutedAt;
  @JsonKey(name: 'is_executed_current_period')
  final bool? isExecutedCurrentPeriod;
  final RecurringWalletDto? wallet;
  final RecurringCategoryDto? category;
  @JsonKey(name: 'payee_id')
  final String? payeeId;
  final RecurringPayeeDto? payee;

  RecurringRuleDto({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.title,
    required this.frequency,
    this.intervalValue,
    this.startDate,
    this.nextRunAt,
    this.endAt,
    required this.isActive,
    this.lastExecutedAt,
    this.isExecutedCurrentPeriod,
    this.wallet,
    this.category,
    this.payeeId,
    this.payee,
  });

  static double _amountFromJson(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _dateFromJson(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory RecurringRuleDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringRuleDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringRuleDtoToJson(this);
}

@JsonSerializable()
class RecurringWalletDto {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  @JsonKey(name: 'currency_code')
  final String? currencyCode;

  RecurringWalletDto({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.currencyCode,
  });

  factory RecurringWalletDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringWalletDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringWalletDtoToJson(this);
}

@JsonSerializable()
class RecurringCategoryDto {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  RecurringCategoryDto({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  factory RecurringCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringCategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringCategoryDtoToJson(this);
}

@JsonSerializable()
class RecurringPayeeDto {
  final String id;
  @JsonKey(name: 'payee_name')
  final String payeeName;
  @JsonKey(name: 'payee_type')
  final String payeeType;
  final String identifier;
  @JsonKey(name: 'bank_code')
  final String? bankCode;
  @JsonKey(name: 'bank_name')
  final String? bankName;

  RecurringPayeeDto({
    required this.id,
    required this.payeeName,
    required this.payeeType,
    required this.identifier,
    this.bankCode,
    this.bankName,
  });

  factory RecurringPayeeDto.fromJson(Map<String, dynamic> json) =>
      _$RecurringPayeeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringPayeeDtoToJson(this);
}