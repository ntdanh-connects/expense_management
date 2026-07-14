import 'package:json_annotation/json_annotation.dart';
part 'ai_digest_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AiDigestDto {
  final String summary;
  final String? insight;
  final List<String>? suggestedQuestions;
  final List<CashflowDayDto>? cashflowChart;

  AiDigestDto({
    required this.summary,
    this.insight,
    this.suggestedQuestions,
    this.cashflowChart
  });

  factory AiDigestDto.fromJson(Map<String,dynamic> json) => _$AiDigestDtoFromJson(json);
}

@JsonSerializable(fieldRename:  FieldRename.snake)
class CashflowDayDto{
  final String date;
  final double dailyIncome;
  final double dailyExpense;
  final double balanceAtEod;

  CashflowDayDto({
    required this.date,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.balanceAtEod
  });

  factory CashflowDayDto.fromJson(Map<String, dynamic> json) {
    return CashflowDayDto(
      date: json['date'] as String,
      dailyIncome: _toDouble(json['daily_income']),
      dailyExpense: _toDouble(json['daily_expense']),
      balanceAtEod: _toDouble(json['balance_at_eod']),
    );
  }
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

