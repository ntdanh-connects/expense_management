import 'package:json_annotation/json_annotation.dart';

part 'report_summary_dto.g.dart';

@JsonSerializable()
class ReportSummaryDto {
  final double income;
  final double expense;
  final double net;

  ReportSummaryDto({
    required this.income,
    required this.expense,
    required this.net,
  });

  factory ReportSummaryDto.fromJson(Map<String, dynamic> json) => _$ReportSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportSummaryDtoToJson(this);
}
