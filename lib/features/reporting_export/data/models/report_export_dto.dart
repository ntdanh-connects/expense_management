import 'package:json_annotation/json_annotation.dart';

part 'report_export_dto.g.dart';

@JsonSerializable()
class ReportExportDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String? type;
  final String status; // pending, processing, completed, failed
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  final Map<String, dynamic>? filters;
  @JsonKey(name: 'exported_at')
  final String? exportedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  ReportExportDto({
    required this.id,
    required this.userId,
    this.type,
    required this.status,
    this.fileUrl,
    this.filters,
    this.exportedAt,
    required this.createdAt,
  });

  factory ReportExportDto.fromJson(Map<String, dynamic> json) => _$ReportExportDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReportExportDtoToJson(this);
}
