import 'package:json_annotation/json_annotation.dart';

part 'report_trend_dto.g.dart';

@JsonSerializable()
class ReportTrendEntryDto {
  final String label;
  final String? date;
  final int? month;
  final int? year;
  final double income;
  final double expense;

  ReportTrendEntryDto({
    required this.label,
    this.date,
    this.month,
    this.year,
    required this.income,
    required this.expense,
  });

  factory ReportTrendEntryDto.fromJson(Map<String, dynamic> json) => _$ReportTrendEntryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportTrendEntryDtoToJson(this);
}
